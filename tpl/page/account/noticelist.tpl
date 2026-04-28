[{capture append="oxidBlock_content"}]
    [{assign var="template_title" value="MY_WISH_LIST"|oxmultilangassign}]

    [{if $oxcmp_shop->oxshops__oxproductive->value}]
        [{oxscript include="js/widget/remove-from-notice.min.js" priority=10}]
    [{else}]
        [{oxscript include="js/widget/remove-from-notice.js" priority=10}]
    [{/if}]

    <div class="row">

        <div class="col-12 col-md-4 col-lg-3 mb-5">
            [{include file="layout/sidebar.tpl" content="account" active_link="noticelist"}]
        </div>

        <div class="col-12 col-md-8 col-lg-9">

            <h1 class="title-big">[{oxmultilang ident="MY_WISH_LIST"}]</h1>
            <hr>

            [{if $oView->getNoticeProductList()}]
                <div class="component__productslider">
                    [{include file="widget/product/list_splide.tpl" listId="noticelistProductList" products=$oView->getNoticeProductList() removeFunction="tonoticelist" owishid=$oxcmp_user->oxuser__oxid->value splideConfig='{"mediaQuery":"min","perMove":1,"arrows":false,"pagination":true,"breakpoints":{"1400":{"perPage":3},"992":{"perPage":2},"768":{"perPage":2},"0":{"perPage":1}}}'}]
                </div>
            [{else}]
                <p class="alert alert-info">[{oxmultilang ident="WISH_LIST_EMPTY"}]</p>
            [{/if}]

        </div>

    </div>
    [{insert name="oxid_tracker" title=$template_title}]
[{/capture}]

[{include file="layout/page.tpl"}]