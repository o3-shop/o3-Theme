<div class="form-check">
    <input value="[{$sPaymentID}]" class="form-check-input" type="radio" name="paymentid" id="payment_[{$sPaymentID}]" [{if $oView->getCheckedPaymentId() == $paymentmethod->oxpayments__oxid->value}]checked[{/if}]>
    <label class="form-check-label" for="payment_[{$sPaymentID}]">
        <span>
            [{$paymentmethod->oxpayments__oxdesc->value}]

            [{if $paymentmethod->getPrice()}]
                [{assign var="oPaymentPrice" value=$paymentmethod->getPrice() }]
                [{if $oViewConf->isFunctionalityEnabled('blShowVATForPayCharge') }]
                    [{strip}]
                        ([{oxprice price=$oPaymentPrice->getNettoPrice() currency=$currency}]
                        [{if $oPaymentPrice->getVatValue() > 0}]
                            [{oxmultilang ident="PLUS_VAT"}] [{oxprice price=$oPaymentPrice->getVatValue() currency=$currency}]
                        [{/if}])
                    [{/strip}]
                [{else}]
                    ([{oxprice price=$oPaymentPrice->getBruttoPrice() currency=$currency}])
                [{/if}]
            [{/if}]
        </span>

        [{foreach from=$paymentmethod->getDynValues() item=value name=PaymentDynValues}]
            <div class="form-group">
                <label class="control-label col-lg-3" for="[{$sPaymentID}]_[{$smarty.foreach.PaymentDynValues.iteration}]">[{$value->name}]</label>
                <div class="col-lg-9">
                    <input id="[{$sPaymentID}]_[{$smarty.foreach.PaymentDynValues.iteration}]" type="text" class="form-control textbox" size="20" maxlength="64" name="dynvalue[[{$value->name}]]" value="[{$value->value}]">
                </div>
            </div>
        [{/foreach}]

        [{block name="checkout_payment_longdesc"}]
            [{if $paymentmethod->oxpayments__oxlongdesc->value|strip_tags|trim}]
                <span class="desc">
                    [{$paymentmethod->oxpayments__oxlongdesc->getRawValue()}]
                </span>
            [{/if}]
        [{/block}]

    </label>
</div>