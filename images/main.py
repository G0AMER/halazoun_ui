import tensorflow as tf
from tensorflow.keras.preprocessing import image_dataset_from_directory

# Chemin vers le dossier des données
dataset_path = "dataset"

# Chargement des données avec normalisation
train_dataset = image_dataset_from_directory(
    dataset_path,
    validation_split=0.2,  # 80% pour l'entraînement, 20% pour la validation
    subset="training",
    seed=123,
    image_size=(224, 224),  # Taille d'image pour MobileNetV2
    batch_size=32
)

val_dataset = image_dataset_from_directory(
    dataset_path,
    validation_split=0.2,
    subset="validation",
    seed=123,
    image_size=(224, 224),
    batch_size=32
)

# Extract class names
class_names = train_dataset.class_names
print("Class names:", class_names)

# Normalisation des images
def normalize_img(image, label):
    image = tf.cast(image, tf.float32) / 255.0
    return image, label

train_dataset = train_dataset.map(normalize_img)
val_dataset = val_dataset.map(normalize_img)

# Construction du modèle
base_model = tf.keras.applications.MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,  # Ne pas inclure la couche dense de sortie
    weights='imagenet'
)

base_model.trainable = False  # Ne pas entraîner les couches du modèle de base

# Construction du modèle complet
model = tf.keras.Sequential([
    base_model,
    tf.keras.layers.GlobalAveragePooling2D(),
    tf.keras.layers.Dense(1024, activation='relu'),
    tf.keras.layers.Dense(len(class_names), activation='softmax')  # Nombre de classes
])

# Compilation du modèle
model.compile(
    optimizer=tf.keras.optimizers.Adam(),
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

# Entraînement du modèle
history = model.fit(train_dataset, validation_data=val_dataset, epochs=10)

# Sauvegarde du modèle
model.save("escargot_classifier.h5")
