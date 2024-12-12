# Import required libraries

import numpy as np
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense
import tf2onnx
import onnx
from onnx2pytorch import ConvertModel
import torch

# Step 1: Load the Keras .h5 model
loaded_model = tf.keras.models.load_model("escargot_classifier.h5")


# Convert the model to ONNX format
onnx_model, _ = tf2onnx.convert.from_keras(loaded_model)