# CV_TERM_PROJECT

1. 주제
asfdfasfd

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

