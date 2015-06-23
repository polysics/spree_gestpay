class payment extends SpreeGestpay.module
  GESTPAY_NO_ERROR    = 0
  GESTPAY_NO_ERROR_3D = 8006

  callback: (result) =>

    # This is called when payment is done correctly without 3D Secure code
    # redirect needed. We are making a request to complete the order
    # and we expect response to have a `redirect` param where we are going
    # to redirect user (order completion path).
    if @check(result, GESTPAY_NO_ERROR)
      @log("result: #{result}")
      encriptedString = result.EncryptedString
      @log("performed authorization (encriptedString: #{encriptedString})")
      @log("translating response with an ajax call...")
      $.ajax
        type: "POST"
        url: '/checkout/payment/process_token.json'
        data:
          token: encriptedString
          payment_method_id: '5' #TODO
        dataType: "json"
      .done (response) =>
        token = response.token
        @log("payment is ok! Redirecting to: #{response.redirect}")
      .fail (response) =>
        json = $.parseJSON(response.responseText)
        @log("payment is failed - #{json.error}")
      return

    # This is called when the payment need a 3D Secure Code.
    # We redirect user to the (external) 3D secure code page.
    if @check(result, GESTPAY_NO_ERROR_3D)
      transKey = result.TransKey
      vbv      = result.VBVRisp
      @log("performed 3D authorization (transKey: #{transKey}, vbv: #{vbv})")

      $.ajax
        type: "POST"
        url: '/checkout/payment/process_3d_redirect.json'
        data:
          trans_key: transKey
          vbv: vbv
          payment_method_id: '5' #TODO
        dataType: "json"
      .done (response) =>
        @log("going to redirect to 3d secure")
        @log("trying to redirect you here: #{response.redirect}")
        window.location = response.redirect
      .fail (response) =>
        json = $.parseJSON(response.responseText)
        @log("impossible to redirect - #{json.error}")
      return

    @error("error during authorization", result)

  send: (options) =>
    GestPay.SendPayment(options, @callback)

  # This is called after a second payment is done, this time with
  # 3D Secure Code information. If it has no errors a request is made
  # to complete the order and get the completion path where redirect user to.
  callback3d: (result) =>
    if @check(result, GESTPAY_NO_ERROR)
      encriptedString = result.EncryptedString
      @log("performed 3D authorization (response: #{response})")
      $.ajax
        type: "POST"
        url: '/checkout/payment/process_token.json'
        data:
          token: encriptedString
          payment_method_id: '5' #TODO
        dataType: "json"
      .done (response) =>
        token = response.token
        @log("payment is ok! Redirecting to: #{response.redirect}")
      .fail (response) =>
        json = $.parseJSON(response.responseText)
        @log("payment is failed - #{json.error}")
      return

    @error("error during 3D authorization", result)

  send3d: (options) =>
    @log("sendind payment after 3d verification")
    @log("#{options.TransKey}")
    @log("#{options.PARes}")
    GestPay.SendPayment(options, @callback3d)

  gestpayModuleName: ->
    "payment"

SpreeGestpay.payment = payment
