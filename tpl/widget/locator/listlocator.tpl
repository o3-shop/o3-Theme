[{if $place == "bottom"}]
    [{if $locator}]
        [{include file="widget/locator/paging.tpl" pages=$locator place=$place attributes=$attributes}]
    [{/if}]
[{else}]
    <div class="alist__locatorbar">
        <div class="alist__locatorbar-paging">
            [{if $locator}]
                [{include file="widget/locator/paging.tpl" pages=$locator place=$place}]
            [{/if}]
        </div>
        [{if $sort || $itemsPerPage}]
            <div class="alist__locatorbar-controls">
                [{if $sort}]
                    [{include file="widget/locator/sort.tpl"}]
                [{/if}]
                [{if $itemsPerPage}]
                    [{include file="widget/locator/itemsperpage.tpl"}]
                [{/if}]
            </div>
        [{/if}]
    </div>
[{/if}]
