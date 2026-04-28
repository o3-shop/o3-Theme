document.addEventListener('DOMContentLoaded', function () {
    const paymentForm = document.querySelector('.payment__payments');
    if (!paymentForm) return;

    function updatePaymentFields() {
        paymentForm.querySelectorAll('.form-check').forEach(function (block) {
            const radio = block.querySelector('.form-check-input[type="radio"][name="paymentid"]');
            if (!radio) return;
            const fields = block.querySelectorAll('.form-check-label input, .form-check-label select, .form-check-label textarea');
            fields.forEach(function (field) {
                field.disabled = !radio.checked;
            });
        });
    }

    updatePaymentFields();

    paymentForm.addEventListener('change', function (e) {
        if (e.target && e.target.type === 'radio' && e.target.name === 'paymentid') {
            updatePaymentFields();
        }
    });
});
