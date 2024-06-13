# CV_TERM_PROJECT

### flutter -> flask -> ml model -> flutter flow
송수신 데이터 형식은 base64.
->  각 end point마다 처리하는 방식이 있어야 함. 플러터의 경우는 이미 익혔다(창설프로젝트 참조)

flask server flow
1. request의 json으로부터 base64 string을 받아옴.
body의 key value = image 로 설정해서 플러터측에서 송신받는다.
[code snippet]
data = flask.request.get_json()
    if 'image' not in data:
        return flask.jsonify({'error': '이미지 데이터를 찾을 수 없습니다.'}), 400

2. base64 decoding
base64 text -> binary data 로 변환
[code snippet]
base64_image = data['image']
    try:
        image_data = base64.b64decode(base64_image)
    except Exception as e:
        return flask.jsonify({'error': f'base64 디코딩 에러: {str(e)}'}), 400

3. PIL 이미지 객체로 변환
[code snippet]
try:
    image = PIL.Image.open(io.BytesIO(image_data))
except Exception as e:
    return flask.jsonify({'error': f'이미지 로드 에러: {str(e)}'}), 400

* io.BytesIO(image_data)
base64 decoding한 바이너리 데이터를 파일 객체처럼 다룰 수 있게 해줍니다. 즉, 메모리 내에서 바이너리 데이터를 파일처럼 읽고 쓸 수 있게 하는 것입니다. 이를 통해 디스크에 저장하지 않고도 이미지 데이터를 처리할 수 있습니다.

4. processing
각 프로세싱 항목 참조

5. response data setting
PIL 이미지 객체인 result_image를 jpeg format의 binary data로 버퍼에 저장.
* binary data로 저장될 지 다른 데이터형식으로 저장될 지는 저장받을 객체에 의해 결정됨. 그래서 버퍼(저장받을 객체)를 BytesIO 변수로 선언시킨 것.
flutter로 송신하기 위해 문자열로 encoding
base64 encodeing -> ASCII 문자열
utf-8 문자열로 decoding -> text 문자열
[code snippet]
buffered = io.BytesIO()
result_image.save(buffered, format="JPEG")
result_image_base64 = base64.b64encode(buffered.getvalue()).decode('utf-8')
return flask.jsonify({'result_image': result_image_base64}), 200

### depth estimation - Intel/dpt-large model proccessing
[code snippet]
pipe = pipeline(task="depth-estimation", model="Intel/dpt-large")
result = pipe(image)
result_image = result["depth"]

### detr_resnet_50
- processor와 model
processor: model이 객체 감지를 원활히 하도록 전처리, 감지 후 모델이 출력한 결과를 처리 가능하도록 후처리.
DetrForObjectDetection: 모델 자체

inputs = processor(images=image, return_tensors="pt")
-> image를 전처리 후 pytorch tensor 타입으로 출력

outputs = model(**inputs)
-> python unpacking, key-value 쌍을 함수의 인자로 전달. processor로 처리된 inputs가 {'tensor_key' : pytorch tensor}의 형태인듯?

target_sizes = torch.tensor([image.size[::-1]])
-> python slicing. start index : all, end index : all, step : -1
-> 슬라이싱 결과는 전체 인덱스에 대해 거꾸로 1스텝씩 = (width, height) -> (height, width)
* 왜?
이미지 좌표계와 텐서 좌표계의 차이
    이미지 파일의 size 속성은 일반적으로 (width, height) 형식입니다.
    하지만 많은 딥러닝 프레임워크나 이미지 처리 라이브러리에서는 이미지를 텐서로 변환할 때 (height, width) 형식을 사용합니다. 이는 numpy 배열이나 PyTorch 텐서가 (channels, height, width) 순서를 따르기 때문입니다.
Bounding Box 및 기타 좌표 계산을 위해
    객체 탐지 모델은 이미지 내의 객체 위치를 예측할 때 bounding box 좌표를 사용합니다. 이 좌표는 (left, top, right, bottom) 또는 (x_min, y_min, x_max, y_max)와 같은 형식을 가집니다.
    모델이 예측한 좌표를 실제 이미지 크기와 매칭시키기 위해서는 올바른 height와 width 값이 필요합니다

results = processor.post_process_object_detection(outputs, target_sizes=target_sizes, threshold=0.9)[0]
-> model의 output 후처리.
-> threshold = 신뢰도. 이 값 이상일 때만 탐지된 객체를 유효한 것으로 간주하여 최종 결과에 포함시킴.
-> [0] = 0번째 인덱스 결과만 가져옴. post_process_object_detection 메서드는 여러 이미지의 후처리가 가능해서.
-> 후처리된 결과는 다음과 같이 결과 가져올 수 있는듯 results["scores"], results["labels"], results["boxes"]


draw = ImageDraw.Draw(image)
-> drawable 이미지 객체 생성.

box = [round(i, 2) for i in box.tolist()]
-> round(i, 2) : 각 요소 i를 소수점 두 자리까지 반올림합니다.
-> box.tolist() : PyTorch 텐서 box를 리스트로 변환. 앞으로 box는 리스트가 된다.

model.config.id2label[label.item()]
-> 해당 model 객체 내의 config 객체 내의 딕셔너리 객체인 id2label에 접근한다.
-> [label.item()] : results["labels"] 텐서에서 값을 뽑아 id2label 딕셔너리의 키 값으로 사용.

* .item() : 텐서로부터 값을 뽑는다

draw.text((box[0], box[1]), f"{label_str} {score.item():.3f}", fill="white")
-> text가 시작할 x, y 좌표

### flutter
package:camera/camera.dart;
-> 기본적인 카메라 임베딩 패키지
flutter_camera_ml_vision.dart;
-> camera 패키지로 머신러닝 기능 사용가능. 
-> 기말 프로젝트 목표가 hugging face의 모델 사용해보기 이므로 사용 x


### python
1. __name__ 변수
.py 파일에는 파이썬 인터프리터에 의해 설정되는 __name__이라는 숨겨진 변수가 있다. 
이 변수는 "해당 모듈의 이름"을 가지고 있는 변수로, 현재 .py 파일의 이름을 가지고 있는 변수라는 의미이다. 
ex | abc.py 
-> abc 파일 외부에서의 __name__ = 'abc'
-> abc 파일 내부에서 직접 실행될 때는 '__main__'

### error
1. flask 서버가 local host에서만 접근 가능한 에러
현재 flutter application은 실제 안드로이드 기기에서 디버깅 중이고, 이 때문에 와이파이 IP를 통해 개발 환경의 서버와 통신 중이다. 그런데 flask 서버는 local host에서만 접근 가능해서 접근 오류가 났음. 403 response
-> flask_cors.CORS(server, resources={r"/*": {"origins": "*"}})
-> server.run(host='0.0.0.0', port=5001, debug=True)
둘 중 영향을 끼치는게 어느것인지 모르겠으나 시간관계상 패스

