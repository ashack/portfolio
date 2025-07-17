# Page snapshot

```yaml
- main:
  - heading "Sign in to your account" [level=2]
  - paragraph:
    - text: Or
    - link "create a new account":
      - /url: /users/sign_up
  - text: Email
  - textbox "Email": "' OR '1'='1"
  - text: Password
  - textbox "Password": password
  - checkbox "Remember me"
  - text: Remember me
  - link "Forgot your password?":
    - /url: /users/password/new
  - button "Sign in"
  - text: Or continue with
  - link "Sign up":
    - /url: /users/sign_up
  - link "Forgot your password?":
    - /url: /users/password/new
  - link "Didn't receive confirmation instructions?":
    - /url: /users/confirmation/new
  - link "Didn't receive unlock instructions?":
    - /url: /users/unlock/new
```