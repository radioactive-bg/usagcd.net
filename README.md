WordPress Installation Guide

# Install New WordPress Installation on Virtual Machine

**Install new WordPress installation on virtual machine with oldest user credential.**

It's good to use the same `DB_NAME` and `table_prefix`:

- **DB_NAME:** `________`
- **Table Prefix:** `_____`
- **User Credential:**

- **User:** `________`
- **Pass:** `_______`

- If an email is added in the file, include it as well.

## Override Site URL

Add the following code to your `wp-config.php` file to override the old site URL:

    define('WP_HOME', 'http://localhost/your-project-folder'); // Replace with your desired site URL
    define('WP_SITEURL', 'http://localhost/your-project-folder'); // Replace with your desired WordPress URL

**Or:** Update the URLs manually in the database when importing the database dump.

## Update Permalinks

After importing the database, go to **Settings → Permalinks**, select **Post name**, and click **Save Changes**.

## Deploy Files

Deploy all files into the correct directories from the repository.

## Activate Theme

This website is build with DIVI builder

## Final Steps

1.  Import the database.
2.  Refresh the permalinks again by navigating to **Settings → Permalinks** and clicking **Save Changes**.

Your WordPress installation should now be ready to use!
