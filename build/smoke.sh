#!/usr/bin/env bash
# Storefront smoke test for the dev shop (shop-ce Docker). Usage: build/smoke.sh [base-url]
# Reads build/smoke-urls.txt, logs in as a throw-away test customer (created through the shop's PHP API,
# removed again on exit), places exactly one order, and per URL checks:
#   - HTTP status of the final page and the expected page marker (see smoke-urls.txt, body class cl-<controller>)
#   - error markers (Twig\Error, Fatal, Uncaught, Stack trace, exception.tpl), PHP Warning/Notice/Deprecated,
#     missing translations, leftover template syntax ({% {{ [{ {#, outside <script>/<style>), truncated page (no </html>)
#   - shop error boxes (`alert alert-danger`) on logged-in pages and POSTs
#   - new ERROR/CRITICAL/ALERT/EMERGENCY lines in source/log/oxideshop.log
# Fails (exit 1) on any of it, exit 2 on setup problems (no container, log not written, login failed, 0 URLs).
# Env: SHOP_CONTAINER, DB_CONTAINER, MAILPIT (default http://localhost:8025), SHOP_LOG, SMOKE_ONLY (regex on labels),
#      SMOKE_DUMP=<dir> (save every body there).
set -u
BASE="${1:-http://localhost:8080}"
HERE="$(cd "$(dirname "$0")" && pwd)"
LOG="${SHOP_LOG:-$HERE/../../../../log/oxideshop.log}"
SHOP="${SHOP_CONTAINER:-o3shop-shop-ce-shop-1}"
DB="${DB_CONTAINER:-o3shop-shop-ce-db-1}"
MAILPIT="${MAILPIT:-http://localhost:8025}"
URLS="$HERE/smoke-urls.txt"
EMAIL="smoke-test@example.invalid"
PASS="Smoke-Test-1234"
TMP="$(mktemp -d)"
RC=0
UID_NEW=""; ART=""; ART_STOCK=""; ART_SOLD=""

sql() { docker exec "$DB" sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" -N -e "$0"' "$1" 2>/dev/null; }
sqlv() { docker exec "$DB" sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" -N -e "$0"' "$1" 2>&1 | grep -v 'Using a password'; return "${PIPESTATUS[0]}"; }

cleanup_customer() {
  local out
  out="$(sqlv "set @u=(select oxid from oxuser where oxusername='$EMAIL');
    delete from oxorderarticles where oxorderid in (select oxid from oxorder where oxuserid=@u);
    delete from oxorder where oxuserid=@u;
    delete from oxuserpayments where oxuserid=@u;
    delete from oxuserbasketitems where oxbasketid in (select oxid from oxuserbaskets where oxuserid=@u);
    delete from oxuserbaskets where oxuserid=@u;
    delete from oxnewssubscribed where oxuserid=@u;
    delete from oxreviews where oxuserid=@u;
    delete from oxratings where oxuserid=@u;
    delete from oxrecommlists where oxuserid=@u;
    delete from oxobject2group where oxobjectid=@u;
    delete from oxaddress where oxuserid=@u;
    delete from oxpricealarm where oxemail='$EMAIL';
    delete from oxuser where oxid=@u;")" || { echo "WARNING: cleanup SQL failed: $out"; RC=3; }
  if [ "$(sql "select count(*) from oxuser where oxusername='$EMAIL'")" != 0 ]; then
    echo "WARNING: test customer $EMAIL still exists after cleanup - delete it by hand"; RC=3
  fi
}
finish() {
  cleanup_customer
  if [ -n "$ART" ] && [ -n "$ART_STOCK" ]; then
    sqlv "update oxarticles set oxstock=$ART_STOCK, oxsoldamount=$ART_SOLD where oxid='$ART'" >/dev/null || { echo "WARNING: stock of $ART not restored"; RC=3; }
  fi
  # remove only the Mailpit messages this run caused (they all mention the test customer address)
  curl -s -m 10 -X DELETE "$MAILPIT/api/v1/search?query=$(printf '%s' "$EMAIL" | sed 's/@/%40/')" >/dev/null 2>&1 || echo "note: Mailpit not reachable, run mails left in place"
  rm -rf "$TMP"
  exit "$RC"
}
trap finish EXIT

[ -f "$URLS" ] || { echo "missing $URLS"; RC=2; exit 2; }
[ -f "$LOG" ] || { echo "shop log $LOG does not exist (theme not under source/? set SHOP_LOG)"; RC=2; exit 2; }
docker exec "$SHOP" true 2>/dev/null || { echo "cannot reach container $SHOP"; RC=2; exit 2; }
cleanup_customer

# canary: an unknown controller makes the shop log a warning; proves the container writes to $LOG
cb="$(wc -c < "$LOG")"; curl -s -o /dev/null -m 60 "$BASE/index.php?cl=smokecanary$$"
[ "$(wc -c < "$LOG")" -gt "$cb" ] || { echo "canary failed: shop did not write to $LOG - new ERRORs would go unnoticed"; RC=2; exit 2; }

cat > "$TMP/mk.php" <<PHP
<?php
require "source/bootstrap.php";
\$u = oxNew(\OxidEsales\Eshop\Application\Model\User::class);
\$u->assign(["oxusername"=>"$EMAIL","oxfname"=>"Smoke","oxlname"=>"Tester","oxstreet"=>"Teststrasse","oxstreetnr"=>"1","oxzip"=>"79098","oxcity"=>"Freiburg","oxcountryid"=>"a7c40f631fc920687.20179984","oxrights"=>"user","oxactive"=>1]);
\$u->setPassword("$PASS");
\$u->save();
\$u->addToGroup("oxidnewcustomer");
\$u->addToGroup("oxidcustomer");
echo "UID:", \$u->getId();
PHP
docker cp "$TMP/mk.php" "$SHOP:/tmp/smoke-mk.php" >/dev/null
UID_NEW="$(docker exec -w /var/www/html "$SHOP" php /tmp/smoke-mk.php 2>&1 | grep -o 'UID:[0-9a-f.]*' | tail -1 | sed 's/UID://')"
[[ "$UID_NEW" =~ ^[0-9a-f.]+$ ]] || { echo "test customer creation failed"; RC=2; exit 2; }
[ "$(sql "select count(*) from oxuser where oxid='$UID_NEW'")" = 1 ] || { echo "test customer not in DB"; RC=2; exit 2; }

# placeholder values from the shop DB (demo data)
VARPARENT="$(sql "select oxid from oxarticles where oxparentid='' and oxactive=1 and oxvarcount>0 order by oxid limit 1")"
PHN="CATEGORY CATEGORY_PARENT ARTICLE VARPARENT VARCHILD MANUFACTURER CONTENT TERM"
PH_CATEGORY="$(sql "select c.oxid from oxcategories c join oxobject2category o on o.oxcatnid=c.oxid join oxarticles a on a.oxid=o.oxobjectid where c.oxactive=1 and a.oxactive=1 group by c.oxid order by count(*) desc, c.oxid limit 1")"
PH_CATEGORY_PARENT="$(sql "select oxparentid from oxcategories where oxparentid<>'oxrootid' and oxactive=1 order by oxid limit 1")"
PH_ARTICLE="$(sql "select oxid from oxarticles where oxparentid='' and oxactive=1 and oxvarcount=0 and oxstock>0 and oxprice>0 order by oxid limit 1")"
PH_VARPARENT="$VARPARENT"
PH_VARCHILD="$(sql "select oxid from oxarticles where oxparentid='$VARPARENT' and oxactive=1 order by oxid limit 1")"
PH_MANUFACTURER="$(sql "select oxid from oxmanufacturers where oxactive=1 order by oxid limit 1")"
PH_CONTENT="$(sql "select oxid from oxcontents where oxloadid='oxagb' and oxtype=0 limit 1")"
PH_TERM="$(sql "select substring_index(oxtitle,' ',1) from oxarticles where oxid='$PH_ARTICLE'" | sed 's/[^A-Za-z0-9]//g')"
for k in $PHN; do v="PH_$k"; [ -n "${!v}" ] || { echo "placeholder {$k} unresolved (demo data missing?)"; RC=2; exit 2; }; done
[[ "$PH_ARTICLE" =~ ^[0-9a-f.]+$ ]] || { echo "unexpected article id"; RC=2; exit 2; }
ART="$PH_ARTICLE"
read -r ART_STOCK ART_SOLD <<< "$(sql "select oxstock, oxsoldamount from oxarticles where oxid='$ART'")"

stoken() { grep -o 'name="stoken" value="[^"]*"' "$1" 2>/dev/null | head -1 | sed 's/.*value="//;s/"//'; }
fetch() { # jar method url [post] -> body in $TMP/body; prints "<http code>"
  local jar="$1" m="$2" url="$3" post="${4:-}"
  if [ "$m" = POST ]; then
    curl -sL -m 90 --max-redirs 10 -c "$TMP/jar-$jar" -b "$TMP/jar-$jar" -o "$TMP/body" -w '%{http_code}' --data "$post" "$url"
  else
    curl -sL -m 90 --max-redirs 10 -c "$TMP/jar-$jar" -b "$TMP/jar-$jar" -o "$TMP/body" -w '%{http_code}' "$url"
  fi
}

# log in the test customer (fatal on failure: otherwise every user URL would "pass" on the login form)
fetch user GET "$BASE/index.php?cl=account" >/dev/null; cp "$TMP/body" "$TMP/last-user"
fetch user POST "$BASE/index.php" "cl=account&actcontrol=account&fnc=login_noredirect&lgn_usr=$EMAIL&lgn_pwd=${SMOKE_PASS:-$PASS}&stoken=$(stoken "$TMP/last-user")" >/dev/null
fetch user GET "$BASE/index.php?cl=account" >/dev/null; cp "$TMP/body" "$TMP/last-user"
if ! grep -q 'fnc=logout' "$TMP/last-user"; then
  echo "login of the test customer failed (no logout link on the account page) - aborting"; RC=2; exit 2
fi

FAILS="$TMP/fails"; : > "$FAILS"
N=0; BAD=0
printf '%-5s %-26s %-9s %-4s %s\n' AUTH LABEL STATUS LOG RESULT
while read -r auth want label expect method path post; do
  case "$auth" in ''|\#*) continue;; esac
  [ -n "${SMOKE_ONLY:-}" ] && ! [[ "$label" =~ $SMOKE_ONLY ]] && continue
  for k in $PHN; do v="PH_$k"; path="${path//\{$k\}/${!v}}"; post="${post//\{$k\}/${!v}}"; expect="${expect//\{$k\}/${!v}}"; done
  if [[ "$post" == *'{STOKEN}'* ]]; then post="${post//\{STOKEN\}/$(stoken "$TMP/last-$auth")}"; fi
  if [[ "$post" == *'{MD5}'* ]]; then
    md5="$(grep -o 'name="sDeliveryAddressMD5" value="[^"]*"' "$TMP/last-$auth" | head -1 | sed 's/.*value="//;s/"//')"
    post="${post//\{MD5\}/$md5}"
  fi
  N=$((N+1))
  before="$(wc -c < "$LOG")"
  code="$(fetch "$auth" "$method" "$BASE$path" "$post")"
  cp "$TMP/body" "$TMP/last-$auth"
  [ -n "${SMOKE_DUMP:-}" ] && { mkdir -p "$SMOKE_DUMP"; cp "$TMP/body" "$SMOKE_DUMP/$label.html"; }
  errs="$(tail -c +$((before+1)) "$LOG" | grep -E '\.(ERROR|CRITICAL|ALERT|EMERGENCY):')"
  nerr=0; [ -n "$errs" ] && nerr="$(printf '%s\n' "$errs" | wc -l | tr -d ' ')"
  perl -0pe 's#<script\b.*?</script>##gis; s#<style\b.*?</style>##gis' "$TMP/body" > "$TMP/stripped"
  first=""
  if m="$(grep -m1 -o -E '.{0,60}(Twig\\Error|Fatal|Uncaught|exception\.tpl|Stack trace).{0,100}' "$TMP/body")" && [ -n "$m" ]; then first="body marker: $(printf '%s' "$m" | tr -s ' \n' ' ')"
  elif m="$(grep -m1 -o -E '(Warning|Notice|Deprecated)(</b>)?: .{0,120} on line [0-9]+' "$TMP/body")" && [ -n "$m" ]; then first="PHP message in body: $m"
  elif m="$(grep -m1 -o -E 'ERROR: Translation.{0,80}' "$TMP/body")" && [ -n "$m" ]; then first="missing translation: $m"
  elif m="$(grep -m1 -o -E '.{0,40}(\{%|\{\{|\[\{|\{#).{0,60}' "$TMP/stripped")" && [ -n "$m" ]; then first="leftover template syntax: $(printf '%s' "$m" | tr -s ' \n' ' ')"
  elif ! grep -q '</html>' "$TMP/body"; then first="truncated or empty page (no </html>)"
  fi
  [ -z "$first" ] && [ -n "$errs" ] && first="$(printf '%s\n' "$errs" | head -1 | sed -E 's/^\[[^]]*\] //' | cut -c1-220)"
  [ -z "$first" ] && [ "$code" != "$want" ] && first="HTTP $code, expected $want"
  if [ -z "$first" ] && { [ "$auth" = user ] || [ "$method" = POST ]; } && grep -q 'class="alert alert-danger"' "$TMP/body"; then
    first="shop error box: $(perl -0ne 'print $1 if /class="alert alert-danger"[^>]*>\s*(.*?)\s*</s' "$TMP/body" | tr -s ' \n' ' ' | cut -c1-150)"
  fi
  if [ -z "$first" ] && [ "$expect" != - ]; then
    IFS='~' read -r -a pats <<< "$expect"
    for p in "${pats[@]}"; do grep -q -E -i -- "$p" "$TMP/body" || { first="expected page marker not found: '$p' (wrong page or redirect?)"; break; }; done
  fi
  if [ -n "$first" ]; then res=FAIL; BAD=$((BAD+1)); printf '%s\t%s\n' "$label" "$first" >> "$FAILS"; else res=ok; fi
  printf '%-5s %-26s %-9s %-4s %s\n' "$auth" "$label" "$code/$want" "$nerr" "$res"
done < "$URLS"

# the checkout flow must have produced exactly one order for the test customer
if [ -z "${SMOKE_ONLY:-}" ] && [ "$N" -gt 0 ]; then
  n_ord="$(sql "select count(*) from oxorder where oxuserid='$UID_NEW'")"
  if [ "$n_ord" != 1 ]; then BAD=$((BAD+1)); N=$((N+1)); printf '%s\t%s\n' "order-created" "expected exactly 1 oxorder row for the test customer, found '$n_ord'" >> "$FAILS"; printf '%-5s %-26s %-9s %-4s %s\n' sql order-created - - FAIL; fi
fi

echo
if [ "$N" -eq 0 ]; then echo "no URLs were run (SMOKE_ONLY='${SMOKE_ONLY:-}' matched nothing?)"; RC=2; exit 2; fi
echo "$((N-BAD))/$N green, $BAD failing"
if [ "$BAD" -gt 0 ]; then
  echo "--- failures (first error per URL) ---"
  while IFS=$'\t' read -r l e; do printf '%-26s %s\n' "$l" "$e"; done < "$FAILS"
  [ "$RC" = 0 ] && RC=1
fi
