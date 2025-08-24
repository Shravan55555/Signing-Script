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

# Ask the user if they want to use default values or enter new ones
read -p "Do you want to use the default subject line: '$default_subject'? (y/n): " use_default

if [ "$use_default" == "y" ]; then
    subject="$default_subject"
else
    echo "Enter certificate details:"
    read -p "Country (C) [PH]: " country
    country=${country:-PH}
    
    read -p "State (ST) [Philippines]: " state
    state=${state:-Philippines}
    
    read -p "City (L) [Manila]: " city
    city=${city:-Manila}
    
    read -p "Organization (O) [RexC]: " org
    org=${org:-RexC}
    
    read -p "Organizational Unit (OU) [RexC]: " ou
    ou=${ou:-RexC}
    
    read -p "Common Name (CN) [RexC]: " cn
    cn=${cn:-RexC}
    
    read -p "Email Address [dtiven13@gmail.com]: " email
    email=${email:-dtiven13@gmail.com}
    
    subject="/C=$country/ST=$state/L=$city/O=$org/OU=$ou/CN=$cn/emailAddress=$email"
fi

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
