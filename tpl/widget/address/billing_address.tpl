<address[{if $collapse}] id="[{$collapse}]" class="collapse show"[{/if}]>
    [{if $oxcmp_user->oxuser__oxcompany->value}][{$oxcmp_user->oxuser__oxcompany->value}]<br>[{/if}]
    [{if $oxcmp_user->oxuser__oxaddinfo->value}][{$oxcmp_user->oxuser__oxaddinfo->value}]<br>[{/if}]
    [{if $oxcmp_user->oxuser__oxustid->value}][{oxmultilang ident="VAT_ID_NUMBER"}] [{$oxcmp_user->oxuser__oxustid->value}]<br>[{/if}]

    [{if $oxcmp_user->oxuser__oxsal->value || $oxcmp_user->oxuser__oxfname->value || $oxcmp_user->oxuser__oxlname->value}]
        [{$oxcmp_user->oxuser__oxsal->value|oxmultilangsal}]&nbsp;[{$oxcmp_user->oxuser__oxfname->value}]&nbsp;[{$oxcmp_user->oxuser__oxlname->value}]
        <br>
    [{/if}]

    [{if $oxcmp_user->oxuser__oxstreet->value || $oxcmp_user->oxuser__oxstreetnr->value}]
        [{$oxcmp_user->oxuser__oxstreet->value}]&nbsp;[{$oxcmp_user->oxuser__oxstreetnr->value}]
        <br>
    [{/if}]

    [{if $oxcmp_user->oxuser__oxstateid->value}]
        [{$oxcmp_user->oxuser__oxstateid->value}]
        <br>
    [{/if}]

    [{if $oxcmp_user->oxuser__oxzip->value || $oxcmp_user->oxuser__oxcity->value}]
        [{$oxcmp_user->oxuser__oxzip->value}]&nbsp;[{$oxcmp_user->oxuser__oxcity->value}]
        <br>
    [{/if}]

    [{if $oxcmp_user->oxuser__oxcountry->value}]
        [{$oxcmp_user->oxuser__oxcountry->value}]
        <br><br>
    [{/if}]

    [{if $oxcmp_user->oxuser__oxusername->value}]
        [{oxmultilang ident="EMAIL" suffix="COLON"}]&nbsp;[{$oxcmp_user->oxuser__oxusername->value}]
        [{if $oxcmp_user->oxuser__oxfon->value || $oxcmp_user->oxuser__oxfax->value || $oxcmp_user->oxuser__oxmobfon->value || $oxcmp_user->oxuser__oxprivfon->value}]<br><br>[{/if}]
    [{/if}]

    [{if $oxcmp_user->oxuser__oxfon->value}][{oxmultilang ident="PHONE" suffix="COLON"}]&nbsp;[{$oxcmp_user->oxuser__oxfon->value}]<br>[{/if}]
    [{if $oxcmp_user->oxuser__oxfax->value}][{oxmultilang ident="FAX" suffix="COLON"}]&nbsp;[{$oxcmp_user->oxuser__oxfax->value}]<br>[{/if}]
    [{if $oxcmp_user->oxuser__oxmobfon->value}][{oxmultilang ident="CELLUAR_PHONE" suffix="COLON"}]&nbsp;[{$oxcmp_user->oxuser__oxmobfon->value}]<br>[{/if}]
    [{if $oxcmp_user->oxuser__oxprivfon->value}][{oxmultilang ident="PERSONAL_PHONE" suffix="COLON"}]&nbsp;[{$oxcmp_user->oxuser__oxprivfon->value}][{/if}]
</address>