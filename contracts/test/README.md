Tests to be done:
- Check that the functions are called when the SC status is ready for it.
    - The seed must be provided when the payment is sent, not before.
    - The claim to be reimbursed must be done after the seed is realised.
- Check that the user that is executing each function is the one assigned
- Check that the payment is at least the price of the product (and that the excess is returned to the buyer)
- Checks regarding to the claim of payment reimbursed:
    - i, ki and MPKi generates MRK and ki != H(s+i)
    - if both are True the buyer is reimbursed
    - else the seller gets the payment

![Diagram](../figures/work_flow1step.png)