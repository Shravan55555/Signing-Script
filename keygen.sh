#!/bin/bash

# Define destination directory
destination_dir="vendor/lineage-priv/keys"

# Always clean up and recreate directories
echo "Cleaning up old keys and directories..."
rm -rf ~/.android-certs
rm -rf "$destination_dir"

# Create directories
mkdir -p ~/.android-certs
mkdir -p "$destination_dir"

# Define default subject line
default_subject="/C=PH/ST=Philippines/L=Manila/O=RexC/OU=RexC/CN=RexC/emailAddress=dtiven13@gmail.com"

# Automatically use default subject line
subject="$default_subject"

echo "Using subject: $subject"

# Check if make_key script exists
if [ ! -f "development/tools/make_key" ]; then
    echo "Error: development/tools/make_key not found. Make sure you're running this from the Android source root directory."
    exit 1
fi

# Generate keys
echo "Generating keys..."
for key_type in releasekey platform shared media networkstack nfc testkey cyngn-priv-app bluetooth sdk_sandbox verifiedboot; do
    echo "Generating $key_type..."
    ./development/tools/make_key ~/.android-certs/$key_type "$subject"
    if [ $? -ne 0 ]; then
        echo "Error generating $key_type key"
        exit 1
    fi
done

# Move keys to the destination directory
echo "Moving keys to $destination_dir..."
mv ~/.android-certs/* "$destination_dir/"

# Create product.mk file
product_mk_content="# Custom signing keys
PRODUCT_DEFAULT_DEV_CERTIFICATE := $destination_dir/releasekey

# Additional signing certificates
PRODUCT_EXTRA_RECOVERY_KEYS := $destination_dir/releasekey"

echo "$product_mk_content" > "$destination_dir/product.mk"

# Set appropriate permissions
chmod -R 644 "$destination_dir"/*.pk8
chmod -R 644 "$destination_dir"/*.x509.pem
chmod 644 "$destination_dir/product.mk"

# Clean up temporary directory
rm -rf ~/.android-certs

echo "Key generation and setup completed successfully!"
echo "Keys are located in: $destination_dir"
echo "Product makefile created: $destination_dir/product.mk"
echo ""
echo "To use these keys in your build, include the following in your device makefile:"
echo "\$(call inherit-product, $destination_dir/product.mk)"

exit 0
