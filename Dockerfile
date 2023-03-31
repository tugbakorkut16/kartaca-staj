# temel imaj belirleme
FROM python:3.9
# gerekli bağımlılıkları yükleme
RUN pip3 install flask
# çalışma dizinini ayarlama
WORKDIR /app
# uygulama kodunu kopyalama
COPY app.py .
COPY templates /app/templates/
EXPOSE 80
# Flask uygulamasını çalıştırma
CMD ["python", "app.py"]
