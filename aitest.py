# Flask Server Code
from flask import Flask, request, jsonify
import tensorflow as tf
import numpy as np
from PIL import Image
import io
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
# Load the TFLite model
def load_model(model_path):
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    return interpreter

# Preprocess the image (resize and normalize)
def preprocess_image(image_bytes, target_size=(224, 224)):
    # Open the image from bytes
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")

    # Resize the image to the target size
    img = img.resize(target_size)

    # Convert image to numpy array and normalize (scale pixel values to [0, 1])
    img_array = np.array(img, dtype=np.float32) / 255.0

    # Expand dimensions to match the model's input shape (batch size, height, width, channels)
    img_array = np.expand_dims(img_array, axis=0)

    return img_array

# Run inference with the model
def run_inference(interpreter, input_data):
    # Get input and output tensor indices
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # Set the tensor to the input data
    interpreter.set_tensor(input_details[0]['index'], input_data)

    # Run the model
    interpreter.invoke()

    # Get the output tensor
    output_data = interpreter.get_tensor(output_details[0]['index'])

    return output_data

# Decode the output (assuming the output is a label)
def decode_output(output_data):
    predicted_label = np.argmax(output_data)
    return predicted_label

# Load model at server startup
model_path = 'assets/escargot_classifier.tflite'
interpreter = load_model(model_path)

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files['file']

    # Read the file as bytes
    image_bytes = file.read()

    # Preprocess the image
    input_data = preprocess_image(image_bytes)

    # Run inference
    output_data = run_inference(interpreter, input_data)

    # Decode the result
    label = decode_output(output_data)
    print(label)
    return jsonify({"label": int(label)})

if __name__ == '__main__':
    app.run()