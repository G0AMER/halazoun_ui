import os
import json
from inference_sdk import InferenceHTTPClient

# Initialize the client
CLIENT = InferenceHTTPClient(
    api_url="https://detect.roboflow.com",
    api_key="sicB6TGLPiPPqFZDf8zY"
)

# Define the dataset directory
dataset_dir = "dataset"
output_file = "annotations.json"

# Initialize an empty dictionary to store annotations
annotations = {}

# Iterate through the dataset
for root, _, files in os.walk(dataset_dir):
    for file in files:
        if file.endswith((".jpg", ".jpeg", ".png")):  # Ensure it's an image file
            image_path = os.path.join(root, file)
            relative_path = os.path.relpath(image_path, dataset_dir)  # Relative path for the dataset structure

            try:
                # Perform inference
                result = CLIENT.infer(image_path, model_id="snail-bj1ab/2")
                annotations[relative_path] = result  # Store result with the relative path as key
            except Exception as e:
                print(f"Error processing {image_path}: {e}")

# Save the annotations to a JSON file
with open(output_file, "w") as f:
    json.dump(annotations, f, indent=4)

print(f"Annotations saved to {output_file}")
