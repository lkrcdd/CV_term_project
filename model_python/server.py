import base64
import io
import os
import flask
import PIL
import torch
import cv2
import PIL
from transformers import pipeline
import flask_cors
import modules_model

server = flask.Flask(__name__)
# CORS 설정
flask_cors.CORS(server, resources={r"/*": {"origins": "*"}})

# @server.route('/')
# def hello_world():
#     return flask.jsonify({'result': 'hello_world'}), 200

@server.route("/depth", methods=["POST"])
def processing_depth():
    data = flask.request.get_json()
    if 'image' not in data:
        return flask.jsonify({'error': '이미지 데이터를 찾을 수 없습니다.'}), 400
    
    # base64 decode
    base64_image = data['image']
    try:
        image_data = base64.b64decode(base64_image)
    except Exception as e:
        return flask.jsonify({'error': f'base64 디코딩 에러: {str(e)}'}), 400

    # 디코딩된 데이터로 이미지 인스턴스 획득
    try:
        image = PIL.Image.open(io.BytesIO(image_data))
    except Exception as e:
        return flask.jsonify({'error': f'이미지 로드 에러: {str(e)}'}), 400

    # processing
    # pipe = pipeline(task="depth-estimation", model="Intel/dpt-large")
    # result = pipe(image)
    # result_image = result["depth"]
    result_image = modules_model.estimate_depth(image)

    # response base 64 string
    buffered = io.BytesIO()
    result_image.save(buffered, format="JPEG")
    result_image_base64 = base64.b64encode(buffered.getvalue()).decode('utf-8')
    
    return flask.jsonify({'result_image': result_image_base64}), 200

@server.route("/detection", methods=["POST"])
def processing_detection():
    data = flask.request.get_json()
    if 'image' not in data:
        return flask.jsonify({'error': '이미지 데이터를 찾을 수 없습니다.'}), 400
    
    # base64 decode
    base64_image = data['image']
    try:
        image_data = base64.b64decode(base64_image)
    except Exception as e:
        return flask.jsonify({'error': f'base64 디코딩 에러: {str(e)}'}), 400

    try:
        image = PIL.Image.open(io.BytesIO(image_data))
    except Exception as e:
        return flask.jsonify({'error': f'이미지 로드 에러: {str(e)}'}), 400

    # processing
    result_image = modules_model.detect_object(image)

    # response base 64 string
    buffered = io.BytesIO()
    result_image.save(buffered, format="JPEG")
    result_image_base64 = base64.b64encode(buffered.getvalue()).decode('utf-8')
    
    return flask.jsonify({'result_image': result_image_base64}), 200

@server.route("/text", methods=["POST"])
def processing_text():
    data = flask.request.get_json()
    if 'image' not in data:
        return flask.jsonify({'error': '이미지 데이터를 찾을 수 없습니다.'}), 400
    
    # base64 decode
    base64_image = data['image']
    try:
        image_data = base64.b64decode(base64_image)
    except Exception as e:
        return flask.jsonify({'error': f'base64 디코딩 에러: {str(e)}'}), 400

    try:
        image = PIL.Image.open(io.BytesIO(image_data)).convert("RGB")
    except Exception as e:
        return flask.jsonify({'error': f'이미지 로드 에러: {str(e)}'}), 400

    # processing
    result_text = modules_model.recognize_text(image)

    return flask.jsonify({'result_text': result_text}), 200

if __name__ == '__main__':
    server.run(host='0.0.0.0', port=5001, debug=True)