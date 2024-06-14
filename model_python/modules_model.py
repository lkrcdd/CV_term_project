from transformers import DetrImageProcessor, DetrForObjectDetection
import torch
from PIL import Image, ImageDraw, ImageFont

def object_detection(image):
    processor = DetrImageProcessor.from_pretrained("facebook/detr-resnet-50", revision="no_timm")
    model = DetrForObjectDetection.from_pretrained("facebook/detr-resnet-50", revision="no_timm")

    # 이미지 처리.
    inputs = processor(images=image, return_tensors="pt")
    outputs = model(**inputs)
    target_sizes = torch.tensor([image.size[::-1]])
    results = processor.post_process_object_detection(outputs, target_sizes=target_sizes, threshold=0.9)[0]

    colors = ["red", "orange", "yellow", "green", "blue", "cyan", "purple"]

    label_colors = {}
    for idx, label in enumerate(results["labels"].unique()):
        label_colors[label.item()] = colors[idx % len(colors)]

    font = ImageFont.load_default(200)

    # 최종 출력하기.
    draw = ImageDraw.Draw(image)
    for score, label, box in zip(results["scores"], results["labels"], results["boxes"]):
        box = [round(i, 2) for i in box.tolist()]
        print(f"Detected {model.config.id2label[label.item()]} with confidence {round(score.item(), 3)} at location {box}")
        color = label_colors[label.item()]
        draw.rectangle(box, outline=color, width=10)
        label_text = model.config.id2label[label.item()]
        draw.text((box[0], box[1]), f"{label_text} {score.item():.3f}",font=font, fill="white")

    return image
