#!/usr/bin/env bash
# Storefront smoke test for the dev shop (shop-ce Docker). Usage: build/smoke.sh [base-url]
# Reads build/smoke-urls.txt, logs in as a throw-away test customer (created through the shop's PHP API,
# removed again on exit), places one order, and checks every URL for: HTTP status, error markers in the body
# (Twig\Error / Fatal / Uncaught / exception.tpl / Stack trace) and new ERROR/CRITICAL lines in oxideshop.log.
# Exit code 1 on any failure. Env: SHOP_CONTAINER, DB_CONTAINER, SMOKE_ONLY (regex on the label).
set -u
BASE="${1:-http://localhost:8080}"
HERE="$(cd "$(dirname "$0")" && pwd)"
LOG="$HERE/../../../../log/oxideshop.log"
SHOP="${SHOP_CONTAINER:-o3shop-shop-ce-shop-1}"
DB="${DB_CONTAINER:-o3shop-shop-ce-db-1}"
URLS="$HERE/smoke-urls.txt"
EMAIL="smoke-test@example.invalid"
PASS="Smoke-Test-1234"
TMP="$(mktemp -d)"
: >> "$LOG"

sql() { docker exec "$DB" sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" -N -e "$0"' "$1" 2>/dev/null; }

cleanup_customer() {
  sql "set @u=(select oxid from oxuser where oxusername='$EMAIL');
    delete from oxorderarticles where oxorderid in (select oxid from oxorder where oxuserid=@u);
    delete from oxorder where oxuserid=@u;
    delete from oxuserbasketitems where oxbasketid in (select oxid from oxuserbaskets where oxuserid=@u);
    delete from oxuserbaskets where oxuserid=@u;
    delete from oxobject2group where oxobjectid=@u;
    delete from oxpricealarm where oxemail='$EMAIL';
    delete from oxaddress where oxuserid=@u;
    delete from oxuser where oxid=@u;" >/dev/null
}
trap 'cleanup_customer; rm -rf "$TMP"' EXIT
cleanup_customer

cat > "$TMP/mk.php" <<PHP
<?php
require "source/bootstrap.php";
\$u = oxNew(\OxidEsales\Eshop\Application\Model\User::class);
\$u->assign(["oxusername"=>"$EMAIL","oxfname"=>"Smoke","oxlname"=>"Tester","oxstreet"=>"Teststrasse","oxstreetnr"=>"1","oxzip"=>"79098","oxcity"=>"Freiburg","oxcountryid"=>"a7c40f631fc920687.20179984","oxrights"=>"user","oxactive"=>1]);
\$u->setPassword("$PASS");
\$u->save();
\$u->addToGroup("oxidnewcustomer");
\$u->addToGroup("oxidcustomer");
echo \$u->getId();
PHP
docker cp "$TMP/mk.php" "$SHOP:/tmp/smoke-mk.php" >/dev/null || { echo "cannot reach container $SHOP"; exit 2; }
UID_NEW="$(docker exec -w /var/www/html "$SHOP" php /tmp/smoke-mk.php 2>&1 | tail -1)"
[ -n "$(sql "select 1 from oxuser where oxid='$UID_NEW'")" ] || { echo "test customer creation failed: $UID_NEW"; exit 2; }

# placeholder values from the shop DB (demo data)
VARPARENT="$(sql "select oxid from oxarticles where oxparentid='' and oxactive=1 and oxvarcount>0 order by oxid limit 1")"
PHN="CATEGORY CATEGORY_PARENT ARTICLE VARPARENT VARCHILD MANUFACTURER CONTENT"
PH_CATEGORY="$(sql "select c.oxid from oxcategories c join oxobject2category o on o.oxcatnid=c.oxid join oxarticles a on a.oxid=o.oxobjectid where c.oxactive=1 and a.oxactive=1 group by c.oxid order by count(*) desc, c.oxid limit 1")"
PH_CATEGORY_PARENT="$(sql "select oxparentid from oxcategories where oxparentid<>'oxrootid' and oxactive=1 order by oxid limit 1")"
PH_ARTICLE="$(sql "select oxid from oxarticles where oxparentid='' and oxactive=1 and oxvarcount=0 and oxstock>0 and oxprice>0 order by oxid limit 1")"
PH_VARPARENT="$VARPARENT"
PH_VARCHILD="$(sql "select oxid from oxarticles where oxparentid='$VARPARENT' and oxactive=1 order by oxid limit 1")"
PH_MANUFACTURER="$(sql "select oxid from oxmanufacturers where oxactive=1 order by oxid limit 1")"
PH_CONTENT="$(sql "select oxid from oxcontents where oxloadid='oxagb' and oxtype=0 limit 1")"
for k in $PHN; do v="PH_$k"; [ -n "${!v}" ] || { echo "placeholder {$k} unresolved (demo data missing?)"; exit 2; }; done

stoken() { grep -o 'name="stoken" value="[^"]*"' "$1" 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }
fetch() { # jar method url [post] -> body in $TMP/body, prints http code
  local jar="$1" m="$2" url="$3" post="${4:-}"
  if [ "$m" = POST ]; then
    curl -sL -m 90 --max-redirs 10 -c "$TMP/jar-$jar" -b "$TMP/jar-$jar" -o "$TMP/body" -w '%{http_code}' --data "$post" "$url"
  else
    curl -sL -m 90 --max-redirs 10 -c "$TMP/jar-$jar" -b "$TMP/jar-$jar" -o "$TMP/body" -w '%{http_code}' "$url"
  fi
}

# log in the test customer (user jar)
fetch user GET "$BASE/index.php?cl=account" >/dev/null; cp "$TMP/body" "$TMP/last-user"
fetch user POST "$BASE/index.php" "cl=account&actcontrol=account&fnc=login_noredirect&lgn_usr=$EMAIL&lgn_pwd=$PASS&stoken=$(stoken "$TMP/last-user")" >/dev/null
fetch user GET "$BASE/index.php?cl=account" >/dev/null; cp "$TMP/body" "$TMP/last-user"
if ! grep -q 'fnc=logout' "$TMP/last-user"; then
  echo "WARNING: storefront login of the test customer failed; logged-in URLs will fail"
fi

MARK=(-e 'Twig\Error' -e 'Fatal' -e 'Uncaught' -e 'exception.tpl' -e 'Stack trace')
FAILS="$TMP/fails"; : > "$FAILS"
N=0; BAD=0
printf '%-5s %-26s %-9s %-4s %s\n' AUTH LABEL STATUS LOG RESULT
while read -r auth want label method path post; do
  case "$auth" in ''|\#*) continue;; esac
  [ -n "${SMOKE_ONLY:-}" ] && ! [[ "$label" =~ $SMOKE_ONLY ]] && continue
  for k in $PHN; do v="PH_$k"; path="${path//\{$k\}/${!v}}"; post="${post//\{$k\}/${!v}}"; done
  if [[ "$post" == *'{STOKEN}'* ]]; then post="${post//\{STOKEN\}/$(stoken "$TMP/last-$auth")}"; fi
  if [[ "$post" == *'{MD5}'* ]]; then
    md5="$(grep -o 'name="sDeliveryAddressMD5" value="[^"]*"' "$TMP/last-$auth" | head -1 | sed 's/.*value="//;s/"//')"
    post="${post//\{MD5\}/$md5}"
  fi
  N=$((N+1))
  before="$(wc -c < "$LOG")"
  code="$(fetch "$auth" "$method" "$BASE$path" "$post")"
  cp "$TMP/body" "$TMP/last-$auth"
  errs="$(tail -c +$((before+1)) "$LOG" | grep -E '\.(ERROR|CRITICAL|ALERT|EMERGENCY):')"
  nerr=0; [ -n "$errs" ] && nerr="$(printf '%s\n' "$errs" | wc -l | tr -d ' ')"
  first=""
  if grep -q "${MARK[@]}" "$TMP/body"; then
    first="body marker: $(grep -m1 -o -E '.{0,60}(Twig\\Error|Fatal|Uncaught|exception\.tpl|Stack trace).{0,100}' "$TMP/body" | tr -s ' \n' ' ')"
  fi
  [ -z "$first" ] && [ -n "$errs" ] && first="$(printf '%s\n' "$errs" | head -1 | sed -E 's/^\[[^]]*\] //' | cut -c1-220)"
  [ -z "$first" ] && [ "$code" != "$want" ] && first="HTTP $code, expected $want"
  if [ "${code:0:1}" = 5 ] || [ -n "$first" ] || [ "$code" != "$want" ]; then res=FAIL; BAD=$((BAD+1)); printf '%s\t%s\n' "$label" "$first" >> "$FAILS"; else res=ok; fi
  printf '%-5s %-26s %-9s %-4s %s\n' "$auth" "$label" "$code/$want" "$nerr" "$res"
done < "$URLS"

echo
echo "$((N-BAD))/$N green, $BAD failing"
if [ "$BAD" -gt 0 ]; then
  echo "--- failures (first error per URL) ---"
  while IFS=$'\t' read -r l e; do printf '%-26s %s\n' "$l" "$e"; done < "$FAILS"
  exit 1
fi
