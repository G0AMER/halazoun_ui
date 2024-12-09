import tensorflow as tf

# Charger le modèle .h5
model = tf.keras.models.load_model("escargot_classifier.h5")

# Conversion en TensorFlow Lite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Sauvegarde du modèle TensorFlow Lite
with open("escargot_classifier.tflite", "wb") as f:
    f.write(tflite_model)

print("Le modèle TensorFlow Lite a été sauvegardé avec succès sous 'escargot_classifier.tflite'")
