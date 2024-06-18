import PIL.Image
import torch
import cv2
import PIL
from transformers import pipeline
#dd

#image = cv2.imread("images/test_coffee.jpeg")
# print(f'image type : {type(image)}')  #
# print(f'image shape : {image.shape}')  #
# cv2.imshow("Image", image)
# cv2.waitKey(0)

image = 'images/test_coffee.jpeg'
pipe = pipeline(task="depth-estimation", model="Intel/dpt-large")
result = pipe(image)
result_image = result["depth"]
result_image.show()
