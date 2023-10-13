# CaptchaAdapter

CaptchaAdapter is a Hamster module for solving captchas.
We integrate several captcha solutions into one.
We measure all the captcha statistics and store in `hle_resources`.`captcha_statistics` on `db02.blockshopper.com`

## Captcha solutions integrated in CaptchaAdapter

```bash
https://2captcha.com/
https://api.captchas.io/
https://azcaptcha.com/
https://capsolver.com/
```
## How to set up config file 

```bash
captcha:
  two_captcha:
    general: 583bdd2a889a3f0af8d21370xxxxxxxx
  captcha_keys:
    two_captcha_com: 583bdd2a889a3f0af8d21370xxxxxxxx
    captchas_io: 53051e99-63ed01df339b49.xxxxxxxx
    azcaptcha_com: 92whfxnyqp8xmttr3vh6dzljxxxxxxxx
    capsolver_com: CAI-1CD66A0269F9B9B69B4EE81E4C6DXXXX
    capsolver_com_app_id: 123F5180-15C8-40B3-9B2D-11CDFB16XXXX
```

## Usage

### 1. Create a client

```ruby
client = Hamster::CaptchaAdapter.new(:two_captcha_com)
```

or

```ruby
Hamster::CaptchaAdapter.new(:two_captcha_com, timeout:200, polling:10)
```

You can use :captchas_io, :azcaptcha_com instead of :two_captcha_com

```ruby
Hamster::CaptchaAdapter.new(:captchas_io, timeout:200, polling:10)
```

Or

```ruby
Hamster::CaptchaAdapter.new(:azcaptcha_com, timeout:200, polling:10)
```

### 2. Solve a CAPTCHA

There are two types of methods available: `decode` and `decode!`:

- `decode` does not raise exceptions.
- `decode!` may raise a `CaptchaAdapter::Error` if something goes wrong.

If the solution is not available, an empty solution object will be returned.

```ruby
captcha = client.decode_image!(url: 'http://bit.ly/1xXZcKo')
captcha.text        # CAPTCHA solution
captcha.id          # CAPTCHA numeric id
```

#### Image CAPTCHA

You can specify `file`, `path`, `raw`, `raw64` and `url` when decoding an image.

```ruby
client.decode_image!(file: File.open('path/to/my/captcha/file', 'rb'))
client.decode_image!(path: 'path/to/my/captcha/file')
client.decode_image!(raw: File.open('path/to/my/captcha/file', 'rb').read)
client.decode_image!(raw64: Base64.encode64(File.open('path/to/my/captcha/file', 'rb').read))
client.decode_image!(url: 'http://bit.ly/1xXZcKo')
```

#### reCAPTCHA v2

```ruby
captcha = client.decode_recaptcha_v2!(
  googlekey: 'xyz',
  pageurl:   'http://example.com/example=1',
)

# The response will be a text (token), which you can access with the `text` method.

captcha.text
"03AOPBWq_RPO2vLzyk0h8gH0cA2X4v3tpYCPZR6Y4yxKy1s3Eo7CHZRQntxrd..."
```

*Parameters:*

- `googlekey`: the Google key for the reCAPTCHA.
- `pageurl`: the URL of the page with the reCAPTCHA challenge.

#### Invisible reCAPTCHA v2 

```ruby
captcha = client.decode_recaptcha_v2!(
  googlekey: 'xyz',
  pageurl:   'http://example.com/example=1',
  invisible: 1
)

# The response will be a text (token), which you can access with the `text` method.

captcha.text
"03AOPBWq_RPO2vLzyk0h8gH0cA2X4v3tpYCPZR6Y4yxKy1s3Eo7CHZRQntxrd..."
```

*Parameters:*

- `googlekey`: the Google key for the reCAPTCHA.
- `pageurl`: the URL of the page with the reCAPTCHA challenge.
- `invisible`: 1 - means that reCAPTCHA is invisible. 0 - normal reCAPTCHA.

#### reCAPTCHA v3

```ruby
captcha = client.decode_recaptcha_v3!(
  googlekey: 'xyz',
  pageurl:   'http://example.com/example=1',
  action:    'verify',
  min_score: 0.3, # OPTIONAL
)

# The response will be a text (token), which you can access with the `text` method.

captcha.text
"03AOPBWq_RPO2vLzyk0h8gH0cA2X4v3tpYCPZR6Y4yxKy1s3Eo7CHZRQntxrd..."
```

*Parameters:*

- `googlekey`: the Google key for the reCAPTCHA.
- `pageurl`: the URL of the page with the reCAPTCHA challenge.
- `action`: the action name used by the CAPTCHA.
- `min_score`: optional parameter. The minimal score needed for the CAPTCHA resolution. Defaults to `0.3`.

> About the `action` parameter: in order to find out what this is, you need to inspect the JavaScript
> code of the website looking for a call to the `grecaptcha.execute` function.
>
> ```javascript
> // Example
> grecaptcha.execute('6Lc2fhwTAAAAAGatXTzFYfvlQMI2T7B6ji8UVV_f', { action: "examples/v3scores" })
> ````

> About the `min_score` parameter: it's strongly recommended to use a minimum score of `0.3` as higher
> scores are rare.

#### hCaptcha

```ruby
captcha = client.decode_hcaptcha!(
  sitekey: 'xyz',
  pageurl: 'http://example.com/example=1',
)

captcha.text
"P0_eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJwYXNza2V5IjoiNnpWV..."
```

*Parameters:*

- `website_key`: the site key for the hCatpcha.
- `website_url`: the URL of the page with the hCaptcha challenge.

### 3. Using proxy or other custom options

You are allowed to use custom options like `proxy`, `proxytype` or `userAgent` whenever the
2Captcha API supports it. Example:

  ```ruby
  options = {
    sitekey:   'xyz',
    pageurl:   'http://example.com/example=1',
    proxy:     'login:password@123.123.123.123:3128',
    userAgent: 'user agent',
  }

  captcha = client.decode_hcaptcha!(options)
  ```

### 4. Retrieve a previously solved CAPTCHA

```ruby
captcha = client.captcha('130920620') # with 130920620 being the CAPTCHA id
```

### 5. Report an incorrectly solved CAPTCHA for a refund

```ruby
client.report!('130920620', 'reportbad') # with 130920620 being the CAPTCHA id
# returns `true` if successfully reported

client.report!('256892751', 'reportgood') # with 256892751 being the CAPTCHA id
# returns `true` if successfully reported
```

### 6. Get your account balance

```ruby
client.balance
# returns a Float balance in USD.
```

### 7. Get usage statistics for a specific date

```ruby
client.stats(Date.new(2022, 10, 7))
# returns an XML string with your usage statistics.
```

### 7. Bypass Cloudflare Turnstile

Recommend to use :tow_captcha_com for solving turnstile
Result of test:
  :two_captcha_com can solve turnstile.
  :captchas_io cannot solve turnstile.
  :azcaptcha_com cannot solve turnstile.

```ruby
response = client.turnstile({sitekey: '0x4AAAAAAAAjq6WYeRDKmebM', url: 'https://courtindex.sdcourt.ca.gov/CISPublic/namesearch/'})
```

### 8. Example Codes

```bash
/HamsterProjects/lib/captcha_adapter/examples/two_captcha_com.rb
/HamsterProjects/lib/captcha_adapter/examples/captchas_io.rb
/HamsterProjects/lib/captcha_adapter/examples/azcaptcha_com.rb
/HamsterProjects/lib/captcha_adapter/examples/capsolver_com.rb
/HamsterProjects/lib/captcha_adapter/examples/config.yml

```