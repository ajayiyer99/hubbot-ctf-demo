# Hosting on Azure Static Web Apps with Entra ID sign-in

This guide moves the CareBot demo from GitHub Pages to Azure Static Web Apps (SWA)
and puts the whole app behind Microsoft Entra ID, restricted to a single tenant.
The app stays mock-only. There is no backend and no container.

## What this gives you

- The entire site requires an Entra ID sign-in before anything loads.
- Access is limited to accounts in your Entra tenant (single-tenant app registration).
- HTTPS, a global CDN, a free hostname, and optional custom domain are built in.
- Deployment runs from GitHub on every push to `main`.

## What it does NOT do

- It does not gate the source code. This repository is public, so `index.html`
  is readable by anyone on GitHub regardless of hosting. Make the repository
  private if the source itself must be restricted.
- It does not keep the old GitHub Pages copy private. Disable Pages (step 7) or
  the ungated copy stays live.
- Gating the whole app also blocks anonymous phone or QR joins. Only people in
  your tenant can open the demo. This is expected for a full-app gate.

## Cost note

Tenant restriction needs a custom identity provider, which requires the SWA
**Standard** plan (about 9 USD per month). The Free plan only offers a built-in
provider that accepts any Microsoft account, which is not a real gate.

## Prerequisites

- An Azure subscription with rights to create resources.
- Rights to create an app registration in your Entra tenant (or someone who can).
- Owner or admin on this GitHub repository.

## Step 1: Register an Entra application

1. In the Azure portal, go to Microsoft Entra ID, then App registrations, then
   New registration.
2. Name it something like `CareBot Demo (SWA)`.
3. Under Supported account types, choose
   **Accounts in this organizational directory only (single tenant)**. This is
   what enforces the tenant restriction.
4. Leave Redirect URI empty for now (you set it in step 4 once you know the
   hostname). Create the registration.
5. On the Overview page, copy the **Application (client) ID** and the
   **Directory (tenant) ID**. You need both later.
6. Go to Certificates and secrets, then New client secret. Copy the secret
   **Value** immediately (it is shown only once). Note the expiry so you can
   rotate it before it lapses.

## Step 2: Create the Static Web App

1. In the Azure portal, create a resource of type Static Web App.
2. Choose the **Standard** plan.
3. For Deployment, select GitHub and authorize access, then pick this
   repository and the `main` branch.
4. For Build details, choose the Custom preset and set:
   - App location: `/`
   - Api location: leave empty
   - Output location: leave empty
5. Create the resource. Azure commits a deployment workflow to
   `.github/workflows/` and adds the deployment token secret to the repository
   for you. No build runs because the app is a single static file.
6. When the first deployment finishes, copy the app hostname, for example
   `https://<name>.azurestaticapps.net`.

## Step 3: Set the tenant ID in the config

Edit `staticwebapp.config.json` in this repository. In the
`wellKnownOpenIdConfiguration` URL, replace `REPLACE_WITH_TENANT_ID` with the
Directory (tenant) ID from step 1. Commit and push. This is the only place the
tenant ID is needed.

## Step 4: Finish the Entra redirect URI

Back in the app registration, go to Authentication, then Add a platform, then
Web, and add this redirect URI (use your real hostname):

```
https://<name>.azurestaticapps.net/.auth/login/entraid/callback
```

If you add a custom domain later, add its callback URI here too.

## Step 5: Add the client ID and secret as app settings

In the Static Web App, go to Configuration (Application settings) and add:

- `ENTRA_CLIENT_ID` set to the Application (client) ID from step 1.
- `ENTRA_CLIENT_SECRET` set to the client secret Value from step 1.

These names match the `clientIdSettingName` and `clientSecretSettingName` in
`staticwebapp.config.json`. The secret lives only in SWA configuration, never in
the repository.

## Step 6: Test the gate

1. Open the SWA hostname in a private or incognito window.
2. You should be redirected to a Microsoft sign-in prompt.
3. Sign in with an account in your tenant and confirm the demo loads.
4. Try an account outside your tenant and confirm it is denied.

## Step 7: Retire the ungated GitHub Pages site

In the repository, go to Settings, then Pages, and set Source to None. Otherwise
the old ungated copy stays live at the github.io URL. Update any links, including
the join URL and any QR codes, to the new SWA hostname.

## Optional: custom domain

In the Static Web App, go to Custom domains and add your domain, then follow the
DNS validation steps. Remember to add the matching `/.auth/login/entraid/callback`
redirect URI to the Entra app registration.

## How the gate works

- `staticwebapp.config.json` defines a custom OpenID Connect provider named
  `entraid` and requires the `authenticated` role for every route (`/*`).
- Any anonymous request returns 401, which is overridden to redirect to
  `/.auth/login/entraid`.
- The built-in GitHub provider is disabled, and the legacy `aad` login path is
  redirected to the custom provider, so there is one sign-in path only.
- Because the app registration is single-tenant, only your tenant can complete
  sign-in.

## Rotating the secret

Before the client secret expires, create a new one in the app registration and
update `ENTRA_CLIENT_SECRET` in SWA Configuration. Remove the old secret after
the new one is in place.
