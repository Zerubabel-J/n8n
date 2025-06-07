
---

### Document: How to Deploy n8n on Google Cloud Free Tier

This guide details the steps to deploy a functional n8n instance on a Google Cloud `e2-micro` VM, which is part of the "Always Free" tier.

#### **Phase 1: Google Cloud VM and Firewall Setup**

1.  **Create a Google Cloud Account:** Sign up for Google Cloud. This requires a Google account and a credit/debit card for verification (you will not be charged if you stay within the free tier limits).

2.  **Create a Compute Engine VM Instance:**
    *   Navigate to **Compute Engine > VM instances** and click **CREATE INSTANCE**.
    *   **Name:** `n8n-server` (or your preference)
    *   **Region:** `us-central1` (or `us-west1`, `us-east1` for free tier)
    *   **Machine configuration:**
        *   Series: `E2`
        *   Machine type: `e2-micro` (2 vCPU, 1 GB memory)
    *   **Boot disk:**
        *   Operating System: `Debian` (e.g., Debian 11) or `Ubuntu`
        *   Size: `30 GB` or less (10 GB is sufficient)
    *   **Firewall:** Check both `Allow HTTP traffic` and `Allow HTTPS traffic`.
    *   Click **Create**.

3.  **Configure a Firewall Rule for n8n:**
    *   Navigate to **VPC network > Firewall** and click **CREATE FIREWALL RULE**.
    *   **Name:** `allow-n8n-port`
    *   **Direction of traffic:** `Ingress`
    *   **Action on match:** `Allow`
    *   **Targets:** `All instances in the network`
    *   **Source IPv4 ranges:** `0.0.0.0/0`
    *   **Protocols and ports:** Select **TCP** and enter `5678`.
    *   Click **Create**.

4.  **Note Your VM's External IP:** On the **Compute Engine > VM instances** page, find and copy the **External IP** address of your new VM.

#### **Phase 2: Server Setup and n8n Deployment via SSH**

1.  **Connect to the VM:** On the VM instances page, click the **SSH** button next to your VM to open a terminal in your browser.

2.  **Update the Server and Install Docker:** Run the following commands to prepare the server and install Docker.

    ```bash
    # Update all system packages
    sudo apt update && sudo apt upgrade -y

    # Install Docker
    sudo apt install docker.io -y
    ```

3.  **Allow Your User to Run Docker Commands (Optional but Recommended):** This avoids needing `sudo` for every Docker command.

    ```bash
    # Add your current user to the 'docker' group
    sudo usermod -aG docker $USER
    ```
    **Action Required:** After running this command, **close the SSH window and open a new one** for the permission change to take effect.

4.  **Deploy n8n using the `docker run` Command:** This single, optimized command will pull the n8n image, configure it, and start it correctly for a low-resource environment.

    ```bash
    docker run -d \
    --restart always \
    --name n8n \
    -p 5678:5678 \
    -v n8n_data:/home/node/.n8n \
    -e GENERIC_TIMEZONE="Africa/Addis_Ababa" \
    -e NODE_OPTIONS="--max-old-space-size=512" \
    -e N8N_SECURE_COOKIE=false \
    n8nio/n8n
    ```

    *Breakdown of the command's key parameters:*
    *   `--restart always`: Ensures n8n starts automatically if the server reboots.
    *   `--name n8n`: Gives the container a simple name for easy management.
    *   `-v n8n_data:/home/node/.n8n`: Creates a persistent volume to store all your workflows and credentials.
    *   `-e NODE_OPTIONS="--max-old-space-size=512"`: **Crucial for stability.** Limits n8n's RAM usage to 512MB to prevent crashes on the `e2-micro` VM.
    *   `-e N8N_SECURE_COOKIE=false`: **Crucial for access.** Allows you to log in over a standard `http` connection without setting up a domain and SSL.

#### **Phase 3: Access and Verify**

1.  **Access Your n8n Instance:** Open your web browser and navigate to:
    `http://<YOUR_EXTERNAL_IP>:5678`
    (Replace `<YOUR_EXTERNAL_IP>` with the IP address you noted in Phase 1).

2.  **Setup Your n8n Owner Account:** Follow the on-screen instructions to create your main user account. You are now ready to build workflows!

---

### **Useful Docker Management Commands (for future use)**

All commands should be run in the VM's SSH terminal.

*   **Check if n8n is running:**
    ```bash
    docker ps
    ```
*   **View n8n's real-time logs:**
    ```bash
    docker logs -f n8n
    ```
*   **Stop the n8n container:**
    ```bash
    docker stop n8n
    ```
*   **Start the n8n container:**
    ```bash
    docker start n8n
    ```
*   **Restart the n8n container:**
    ```bash
    docker restart n8n
    ```
*   **To update n8n to a newer version:**
    ```bash
    # 1. Pull the latest image
    docker pull n8nio/n8n

    # 2. Stop and remove the old container
    docker stop n8n
    docker rm n8n

    # 3. Relaunch using the exact same 'docker run' command from Phase 2, Step 4.
    # Docker will automatically use the newly pulled image and attach to your existing data volume.
    ```
