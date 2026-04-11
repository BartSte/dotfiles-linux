# connect-iq-sdk-manager sdk current-path --bin
# if has command connect-iq-sdk-manager then
if command -v connect-iq-sdk-manager &>/dev/null; then
    bin=$(connect-iq-sdk-manager sdk current-path --bin 2>/dev/null)
    if [[ -d "$bin" ]]; then
        add_to_path "$bin"
    else
        echo "Garmin Connect IQ SDK Manager found, but bin directory not found. Please check your installation."
    fi
else
    echo "Garmin Connect IQ SDK Manager not found. Please install it to use Garmin Connect IQ development tools."
fi
