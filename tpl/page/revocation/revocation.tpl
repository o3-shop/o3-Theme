[{capture append="oxidBlock_content"}]

[{* §356a BGB electronic revocation form (issue #99). *}]
[{* o3-theme port of wave-theme/revocation.tpl, adapted to Bootstrap 5: *}]
[{*  - drop the wave .controls wrapper (BS5 doesn't need it)                  *}]
[{*  - form-group / oxInValid / req CSS hooks  →  form-floating + is-invalid  *}]
[{*  - jqBootstrapValidation                   →  needs-validation + native   *}]
[{*    HTML5 + BS5 invalid-feedback (matches o3-theme/tpl/form/contact.tpl)   *}]
[{*  - translation keys are storefront-shared in shop-ce/translations         *}]
[{*    (phase 10) — o3-theme inherits them, no per-theme key duplication.     *}]

[{* BS5 native validation toggle. validate.js attaches a submit listener that *}]
[{* flips the form to was-validated; without it, server-side $errors still   *}]
[{* drives is-invalid + the inline invalid-feedback line — graceful baseline.*}]
[{if $oxcmp_shop->oxshops__oxproductive->value}]
    [{oxscript include="js/widget/validate.min.js" priority=10}]
[{else}]
    [{oxscript include="js/widget/validate.js" priority=10}]
[{/if}]

<div class="o3-revocation page-content">
    <div class="container-xxl">

        <h1>[{oxmultilang ident="O3_REVOCATION_FORM_HEADING"}]</h1>

        [{* Operator notice block — rendered above the form via {oxifcontent}.  *}]
        [{* Empty/inactive snippet → block short-circuits → no div emitted →    *}]
        [{* no rogue gap. mt-3 / mb-4 utilities give breathing room above and  *}]
        [{* below ONLY when there's a notice to render.                         *}]
        [{oxifcontent ident="o3_revocation_notice" object="oCont"}]
            <div class="o3-revocation-notice mt-3 mb-4">
                [{$oCont->oxcontents__oxcontent->getRawValue()}]
            </div>
        [{/oxifcontent}]

        [{assign var="errors" value=$oView->getValidationErrors()}]

        <form id="o3-revocation-form"
              class="o3-revocation-form needs-validation"
              method="post"
              action="[{$oViewConf->getSelfActionLink()}]"
              role="form"
              novalidate>
            [{$oViewConf->getHiddenSid()}]
            <input type="hidden" name="cl" value="revocation">
            <input type="hidden" name="fnc" value="submit">

            [{* Name — mandatory. aria-required + the * in the label text are *}]
            [{* the visible required marker required by the form contract. *}]
            <div class="form-floating mb-3">
                <input type="text"
                       id="o3rev_name"
                       name="o3rev_name"
                       class="form-control[{if $errors.o3rev_name}] is-invalid[{/if}]"
                       value="[{$oView->getName()|escape:'html'}]"
                       placeholder="[{oxmultilang ident="O3_REVOCATION_FIELD_NAME_LABEL"}]"
                       required
                       aria-required="true"
                       [{if $errors.o3rev_name}]aria-invalid="true" aria-describedby="o3rev_name_err"[{/if}]>
                <label for="o3rev_name">[{oxmultilang ident="O3_REVOCATION_FIELD_NAME_LABEL"}]*</label>
                <div id="o3rev_name_err" class="invalid-feedback">
                    [{if $errors.o3rev_name}][{oxmultilang ident=$errors.o3rev_name}][{else}][{oxmultilang ident="O3_REVOCATION_VALIDATION_REQUIRED"}][{/if}]
                </div>
            </div>

            [{* Order identification — mandatory. *}]
            <div class="form-floating mb-3">
                <input type="text"
                       id="o3rev_orderident"
                       name="o3rev_orderident"
                       class="form-control[{if $errors.o3rev_orderident}] is-invalid[{/if}]"
                       value="[{$oView->getOrderIdent()|escape:'html'}]"
                       placeholder="[{oxmultilang ident="O3_REVOCATION_FIELD_ORDERNUMBER_LABEL"}]"
                       required
                       aria-required="true"
                       [{if $errors.o3rev_orderident}]aria-invalid="true" aria-describedby="o3rev_orderident_err"[{/if}]>
                <label for="o3rev_orderident">[{oxmultilang ident="O3_REVOCATION_FIELD_ORDERNUMBER_LABEL"}]*</label>
                <div id="o3rev_orderident_err" class="invalid-feedback">
                    [{if $errors.o3rev_orderident}][{oxmultilang ident=$errors.o3rev_orderident}][{else}][{oxmultilang ident="O3_REVOCATION_VALIDATION_REQUIRED"}][{/if}]
                </div>
            </div>

            [{* Email — type=email triggers the email-style mobile keyboard *}]
            [{* and HTML5 client-side hint; server still runs FILTER_VALIDATE_EMAIL. *}]
            <div class="form-floating mb-3">
                <input type="email"
                       id="o3rev_email"
                       name="o3rev_email"
                       class="form-control[{if $errors.o3rev_email}] is-invalid[{/if}]"
                       value="[{$oView->getEmail()|escape:'html'}]"
                       placeholder="[{oxmultilang ident="O3_REVOCATION_FIELD_EMAIL_LABEL"}]"
                       required
                       aria-required="true"
                       [{if $errors.o3rev_email}]aria-invalid="true" aria-describedby="o3rev_email_err"[{/if}]>
                <label for="o3rev_email">[{oxmultilang ident="O3_REVOCATION_FIELD_EMAIL_LABEL"}]*</label>
                <div id="o3rev_email_err" class="invalid-feedback">
                    [{if $errors.o3rev_email}][{oxmultilang ident=$errors.o3rev_email}][{else}][{oxmultilang ident="O3_REVOCATION_VALIDATION_EMAIL_FORMAT"}][{/if}]
                </div>
            </div>

            [{* Free text — optional, NOT required, NO required marker. *}]
            <div class="form-floating mb-3">
                <textarea id="o3rev_freetext"
                          name="o3rev_freetext"
                          class="form-control"
                          placeholder="[{oxmultilang ident="O3_REVOCATION_FIELD_FREETEXT_LABEL"}]"
                          style="height: 8rem;">[{$oView->getFreeText()|escape:'html'}]</textarea>
                <label for="o3rev_freetext">[{oxmultilang ident="O3_REVOCATION_FIELD_FREETEXT_LABEL"}]</label>
            </div>

            [{* Form-level error (token expired, anti-spam reject). *}]
            [{if $errors.form}]
                <div class="alert alert-danger" role="alert">[{oxmultilang ident=$errors.form}]</div>
            [{/if}]

            [{* Single submit button — clicking IS the legally-effective declaration *}]
            [{* per § 356a Abs. 3. *}]
            <div class="mb-3">
                <button type="submit" class="btn btn-primary o3-revocation-submit">
                    [{oxmultilang ident="O3_REVOCATION_CONFIRM_BUTTON"}]
                </button>
            </div>
        </form>
    </div>
</div>

[{/capture}]
[{include file="layout/page.tpl"}]
