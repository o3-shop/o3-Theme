<select[{if $disabled}] disabled[{/if}] name="[{$name}]"
        [{if $class}]class="[{$class}]"[{/if}]
        [{if $id}]id="[{$id}]"[{/if}]
        [{if $required}]required[{/if}]>
    [{block name="salutation_options"}]
        <option value="" [{if empty($value)}]selected [{/if}]>[{oxmultilang ident="DD_SELECT_SALUTATION" suffix="ELLIPSIS"}]</option>
        <option value="MRS" [{if $value|lower  == "mrs" or $value2|lower == "mrs"}]SELECTED[{/if}]>[{oxmultilang ident="MRS"}]</option>
        <option value="MR"  [{if $value|lower  == "mr"  or $value2|lower == "mr"}]SELECTED[{/if}]>[{oxmultilang ident="MR" }]</option>
    [{/block}]
</select>
