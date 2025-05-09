[{capture append="oxidBlock_pageBody"}]
    [{if $oView->isEnabledPrivateSales()}]
        [{oxid_include_widget cl="oxwCookieNote" _parent=$oView->getClassName() nocookie=1}]
    [{/if}]
[{/capture}]
[{capture append="oxidBlock_content"}]

    [{if $oView->showUpdateScreen()}]
        [{assign var="template_title" value="NEW_PASSWORD"|oxmultilangassign}]
    [{elseif $oView->updateSuccess()}]
        [{assign var="template_title" value="CHANGE_PASSWORD"|oxmultilangassign}]
    [{else}]
        [{assign var="template_title" value="FORGOT_PASSWORD"|oxmultilangassign}]
    [{/if}]

    <h1 class="title-big">[{$template_title}]</h1>

    <hr>

    [{if $oView->isExpiredLink()}]
        <div class="alert alert-danger">[{oxmultilang ident="ERROR_MESSAGE_PASSWORD_LINK_EXPIRED"}]</div>
    [{elseif $oView->showUpdateScreen()}]
        [{include file="form/forgotpwd_change_pwd.tpl"}]
    [{elseif $oView->updateSuccess()}]
        <div class="alert alert-success">[{oxmultilang ident="PASSWORD_CHANGED"}]</div>

        <form action="[{$oViewConf->getSelfActionLink()}]" name="forgotpwd" method="post" role="form">

            [{$oViewConf->getHiddenSid()}]
            <input type="hidden" name="cl" value="start">
            <button id="backToShop" class="submitButton btn btn-primary" type="submit">
                [{oxmultilang ident="BACK_TO_SHOP"}]
            </button>

        </form>
    [{else}]
        [{if $oView->getForgotEmail()}]
            [{block name="page_account_forgot_email_sent"}]
                <div class="alert alert-info">[{oxmultilang ident="PASSWORD_WAS_SEND_TO"}] [{$oView->getForgotEmail()}]</div>
                <div class="bar">
                    <form action="[{$oViewConf->getSelfActionLink()}]" name="forgotpwd" method="post">

                            [{$oViewConf->getHiddenSid()}]
                            <input type="hidden" name="cl" value="start">
                            <button id="backToShop" class="btn btn-primary submitButton" type="submit">
                                [{oxmultilang ident="BACK_TO_SHOP"}]
                            </button>

                    </form>
                </div>
            [{/block}]
        [{else}]
            [{include file="form/forgotpwd_email.tpl"}]
        [{/if}]
    [{/if}]

    [{if !$oView->isActive('PsLogin')}]
        [{insert name="oxid_tracker" title=$template_title}]
    [{/if}]
[{/capture}]
[{if $oView->isActive('PsLogin')}]
    [{include file="layout/popup.tpl"}]
[{else}]
    [{include file="layout/page.tpl"}]
[{/if}]

