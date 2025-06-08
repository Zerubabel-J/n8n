
---

### **Definitive Guide: Deploying a Production-Ready n8n Instance on Google Cloud (Free Tier) - V2 (Corrected & Complete)**

This guide documents the final, successful architecture we built. It is robust, secure, and uses professional best practices. It assumes you are starting from nothing.

**The Architecture We Are Building:**
*   A Google Cloud `e2-micro` VM as our server.
*   A custom domain name pointing to the VM.
*   A Docker-based deployment using `docker-compose` for easy management.
*   **Caddy** as a secure reverse proxy to provide automatic, free HTTPS/SSL.
*   **n8n** running securely, accessible only through Caddy.

---

### **Phase 1: Infrastructure Setup (The Foundation)**

#### **Step 1: Get a Domain Name**
This is non-negotiable for a professional setup with HTTPS.
*   **Action:** Purchase a domain from a registrar like Namecheap, Porkbun, or use a subdomain from an existing domain you own.
*   **Why:** Modern security standards (especially for OAuth2) require a valid domain name, not just an IP address.

#### **Step 2: Create the Google Cloud VM**
This is our server, the "land" where we will build our workshop.
*   **Action:**
    1.  Go to the Google Cloud Console -> **Compute Engine -> VM instances**.
    2.  Click **CREATE INSTANCE**.
    3.  Configure with these **exact** "Always Free" tier settings:
        *   **Name:** `n8n-server`
        *   **Region:** `us-central1` (Iowa) or another US free-tier region.
        *   **Machine type:** `e2-micro`.
        *   **Boot disk:** `Debian 11` or a similar Linux OS. Keep size <= 30GB.
        *   **Firewall:** Check both **`Allow HTTP traffic`** and **`Allow HTTPS traffic`**. These are crucial as they create high-priority default firewall rules for ports 80 and 443.
    4.  Click **Create**.
*   **Result:** A running VM with a public **External IP** address. Note this IP.

#### **Step 3: Point Your Domain to the VM**
This is like putting a street sign on your land.
*   **Action:**
    1.  Go to your domain registrar's DNS management panel (e.g., cPanel's Zone Editor).
    2.  Create a new **`A` Record**.
    3.  **Host/Name:** Your chosen subdomain (e.g., `n8n` for `n8n.your-domain.com`).
    4.  **Value/Points to:** The **External IP** of your Google Cloud VM.
    5.  Save the record and wait for DNS propagation (can be checked with `ping n8n.your-domain.com` from your local computer).
*   **Why:** This allows the world to find your server using a friendly name instead of an IP address.

#### **Step 4: Configure the Network Firewall and Tags [CRITICAL STEP]**
This is the secure gatekeeper for our VM. We will use the professional "Network Tag" method to ensure our rules are applied precisely.
*   **Action (Part A - Tag the VM):**
    1.  Go to **Compute Engine -> VM instances**. Click on your `n8n-server` to open its details page.
    2.  Click **EDIT**.
    3.  Scroll down to the **"Network tags"** field.
    4.  Type in a tag, for example, `n8n-server-tag`, and press Enter.
    5.  Click **Save**.
*   **Action (Part B - Create a Targeted Firewall Rule):**
    1.  Go to **VPC network -> Firewall**. Click **CREATE FIREWALL RULE**.
    2.  **Name:** `allow-public-web-traffic` (or a descriptive name).
    3.  **Targets:** Change the dropdown to **`Specified target tags`**.
    4.  **Target tags:** Enter the exact tag you just created: `n8n-server-tag`.
    5.  **Source IPv4 ranges:** `0.0.0.0/0` (This means "allow from any IP address").
    6.  **Protocols and ports:** Select **"Specified protocols and ports,"** check the **TCP** box, and enter the ports `80, 443`.
    7.  Click **Create**.
*   **Why:** This creates an explicit link. The firewall rule `allow-public-web-traffic` now *only* applies to VMs that have the `n8n-server-tag` sticker. This is more secure and manageable than opening ports for all instances in your network. The `Allow HTTP/HTTPS` checkboxes on the VM instance are a good default, but this method is more explicit and controlled.

---

### **Phase 2: Server Configuration (Preparing the Workshop)**

#### **Step 5: Connect to Your VM via SSH**
*   **Action:** On the **VM instances** page, click the **`SSH`** button next to your `n8n-server`.

#### **Step 6: Install Docker and Docker Compose**
*   **Action:** Run the following commands in the SSH terminal:
    ```bash
    # Update the server's package list
    sudo apt update && sudo apt upgrade -y

    # Install Docker and Docker Compose
    sudo apt install docker.io docker-compose -y
    ```

#### **Step 7: Create a Project Directory**
*   **Action:**
    ```bash
    mkdir n8n-caddy
    cd n8n-caddy
    ```
    *All subsequent file creation will happen inside this directory.*

---

### **Phase 3: Application Deployment (Building the Machines)**

#### **Step 8: Create the `docker-compose.yml` File**
*   **Action:**
    1.  Create the file: `nano docker-compose.yml`
    2.  Paste the following complete and corrected code:

        ```yml
        version: '3.7'

        services:
          n8n:
            image: n8nio/n8n
            restart: always
            environment:
              # Set your timezone
              - GENERIC_TIMEZONE=Africa/Addis_Ababa
              # Limit RAM usage for the small VM
              - NODE_OPTIONS=--max-old-space-size=512
              # IMPORTANT: Tell n8n its public address for creating URLs
              - WEBHOOK_URL=https://n8n.your-domain.com/
            volumes:
              - n8n_data:/home/node/.n8n

          caddy:
            image: caddy:latest
            restart: always
            ports:
              # Expose Caddy to the public on the standard web ports
              - "80:80"
              - "443:443"
              - "443:443/udp"
            volumes:
              # Link our Caddyfile to the container
              - ./Caddyfile:/etc/caddy/Caddyfile
              # Create volumes for Caddy's data and certificates
              - caddy_data:/data
              - caddy_config:/config

        volumes:
          n8n_data:
          caddy_data:
          caddy_config:
        ```
    3.  **Crucially, replace `n8n.your-domain.com` with your actual domain name.**
    4.  Save and exit (`Ctrl+X`, `Y`, `Enter`).

#### **Step 9: Create the `Caddyfile`**
*   **Action:**
    1.  Create the file: `nano Caddyfile`
    2.  Paste the following configuration.

        ```
        n8n.your-domain.com {
            reverse_proxy n8n:5678
        }
        ```
    3.  **Again, replace `n8n.your-domain.com` with your actual domain name.** The space between the domain and the `{` is mandatory.
    4.  Save and exit.

#### **Step 10: Launch the Application Stack**
*   **Action:** From inside the `n8n-caddy` directory, run the single launch command:
    ```bash
    docker-compose up -d
    ```

---

### **Phase 4: Finalization and Access**

#### **Step 11: Verify and Access**
*   **Action:**
    1.  Wait about a minute for the services to stabilize and for Caddy to get the certificate.
    2.  Check the status: `docker-compose ps`. Both services should show a state of `Up`.
    3.  Open your browser and navigate to **`https://n8n.your-domain.com`**.
*   **Result:** You will see your n8n instance, running securely with HTTPS.

#### **Step 12: Configure OAuth Credentials**
*   **Action:**
    1.  Go to your Google Cloud Console's API credentials page.
    2.  In your OAuth 2.0 Client ID settings, add your new, permanent redirect URI to the whitelist:
        **`https://n8n.your-domain.com/rest/oauth2-credential/callback`**
    3.  In n8n, you can now create your Google credentials, and the OAuth flow will work perfectly.

Thank you again for catching that omission. The documentation is now truly complete and reflects the robust, secure process we built together.
