[{capture append="oxidBlock_pageBody"}]
    [{if $oView->isEnabledPrivateSales()}]
        [{oxid_include_widget cl="oxwCookieNote" _parent=$oView->getClassName() nocookie=1}]
    [{/if}]
[{/capture}]

[{capture append="oxidBlock_content"}]
    [{assign var="template_title" value="OPEN_ACCOUNT"|oxmultilangassign}]
    [{if $oView->isActive('PsLogin')}]
        [{include file="message/errors.tpl"}]
    [{/if}]

    <h1 class="title-big">[{oxmultilang ident="OPEN_ACCOUNT"}]</h1>
    <hr class="hr-big">

    [{include file="form/register.tpl"}]

    [{insert name="oxid_tracker" title=$template_title}]
[{/capture}]

[{if $oView->isActive('PsLogin')}]
    [{include file="layout/popup.tpl"}]
[{else}]
    [{include file="layout/page.tpl"}]
[{/if}]