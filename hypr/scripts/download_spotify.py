#!/home/smail/.venvs/spotdl/bin/python
import subprocess

# Ask the user to input the Spotify URL
url = input("Enter the Spotify track URL: ")

# Set the output directory
output_dir = "./Music"

# Confirm the URL
print(f"Downloading from URL: {url}")

# Run the spotdl command using the full path
subprocess.run([
    "/home/smail/.venvs/spotdl/bin/spotdl",  # Full path to spotdl executable
    "--output", output_dir,
    url
])
