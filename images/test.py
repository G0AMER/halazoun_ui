import tensorflow as tf
import numpy as np
from tensorflow.keras.preprocessing import image

# Path to your .tflite model
tflite_model_path = "escargot_classifier.tflite"

# Load the TFLite model
interpreter = tf.lite.Interpreter(model_path=tflite_model_path)
interpreter.allocate_tensors()

# Get input and output details for inference
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Load an example image (ensure it's the correct shape and size)
img_path = "20241012_095707.jpg"  # Change this to the actual path of your image
img = image.load_img(img_path, target_size=(224, 224))  # Resize to 224x224
img_array = image.img_to_array(img)  # Convert image to array
img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension
img_array = img_array / 255.0  # Normalize to [0, 1] range

# Set the input tensor
interpreter.set_tensor(input_details[0]['index'], img_array)

# Run the inference
interpreter.invoke()

# Get the output tensor
output_data = interpreter.get_tensor(output_details[0]['index'])

# Print the output
print("Output from TensorFlow Lite model:", output_data)

# Optionally, you can map the output to class labels if you have the class names
class_names = ['Helix Aspersa Maxima Gros Gris', 'Helix Aspersa Petit Gris', 'Escargot Morguet', 'Helix Aperta']  # Example class names
predicted_class = np.argmax(output_data)  # Get the class with the highest probability
print("Predicted class:", class_names[predicted_class])
