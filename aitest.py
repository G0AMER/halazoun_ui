import tensorflow as tf
import numpy as np
from PIL import Image

# Load the TFLite model
def load_model(model_path):
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    return interpreter

# Preprocess the image (resize and normalize)
def preprocess_image(image_path, target_size=(224, 224)):
    # Open the image and convert to RGB if it's not already
    img = Image.open(image_path).convert("RGB")

    # Resize the image to the target size (224x224 is common for many models)
    img = img.resize(target_size)

    # Convert image to numpy array and normalize (scaling pixel values to [0, 1])
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
    # Assuming the output is a probability distribution, you can get the predicted label
    predicted_label = np.argmax(output_data)
    return predicted_label

def main():
    # Load the model
    model_path = 'assets/escargot_classifier.tflite'
    interpreter = load_model(model_path)

    # Preprocess the image
    image_path = "C:/Users/gamer/Downloads/images/04-Helix aperta/Photo 12-14-22 08 56 54.jpg"
    image_data = preprocess_image(image_path)

    # Run inference
    output_data = run_inference(interpreter, image_data)

    # Decode the output (modify as per your model's output format)
    label = decode_output(output_data)

    print(f"Predicted label: {label}")

if __name__ == '__main__':
    main()
