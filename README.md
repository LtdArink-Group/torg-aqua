# KSAZD2AQUa

Интеграция ИС КСАЗД и ИС АКВа

## Общие положения

Внешний интерфейс системы доступен по адресу http://ksazd-aqua.rao-esv.ru

Синхронизация данных по проектам производится ежесуточно в 07:30. Синхронизация данных по лотам производится каждые 10 минут.

## Установка и настройка

### Требования к окружению

Для установки модуля интеграции требуется наличие интерпретатора языка Ruby версии 2.1.0 или выше.

### Установка

Установка производится в директорию `/home/deployer/apps/ksazd2aqua`. Если будет использована другая директория то нужно изменить пути в файлах `config/ksazd2aqua.sh`, `config/nginx.conf`.

Для установки приложения нужно перейти в директорию приложения и запустить команды
``` sh
$ git clone git@github.com:kodram/ksazd2aqua.git .
$ bundle
```

### Настройка

Для настроки параметров системы нужно скопировать файл `config/configuration.example.yml` в `config/configuration.yml` и указать в нем парметры подключения к базе данных и веб-сервисам. Если на сервере не используется proxy для доступа к веб-ресурсам, то нужно удалить параметр `soap.proxy` в конфигурационном файле.

Инициализация базы данных и заполнение данными справочников производится командой
``` shell
$ bundle exec rake db:setup
```

Настройка cron-задач для загрузки проектов и передачи лотов производится командой
``` shell
$ bundle exec whenever -w
```

Проверить результат выполнения можно запуском команды
``` shell
crontab -l
```

Перед запуском веб-сервера необходимо создать символьные ссылки на файлы конфигурации nginx и скрипт запуска веб-сервера
``` shell
$ ln -nfs config/nginx.conf /etc/nginx/sites-available/ksazd2aqua
$ ln -nfs config/ksazd2aqua.sh /etc/init.d/thin-ksazd2aqua
```

Запуск веб-сервера производится командой
```
$ bin/start
```

### Обновление

Для обновления системы следует перейти в директорию системы и запустить команды
``` sh
$ git pull
$ bin/restart
```

## Эксплуатация сиситемы

Для мониторинга состояния системы можно пользоваться веб-интерфейсом. Более подробная информация о работе системы находится в логах в директории `logs`.

### Типичные ошибки и их устранение

Текщие ошибки интеграции отображаются в таблице на странице [http://ksazd-aqua.rao-esv.ru](http://ksazd-aqua.rao-esv.ru). Если текст ошибки начинется с префикса "КСАЗД:" это ошибка на стороне модуля интеграции. Если ошибка начинается с префикса "АКВА:" это ошибка на стороне веб-сервиса ИС АКВа.

#### Ошибки на стороне модуля интеграции



#### Ошибки на стороне веб-сервиса АКВа

Подробную информацию об ошибках на стороне веб-сервиса АКВа можно увидеть в [логе загрузки лотов](http://akva.gidroogk.com:8090/sap/bc/gui/sap/its/webgui?~transaction=ZPPM_KSAZD_LOTS_LOG&sap-client=400&sap-language=RU) (логин: KSZAD, пароль: 654321)

Большая часть из них связанна с ограничениями на отсутствие данных в обязательных для заполнения полях. Иногда могут быть ошибки связанные с отсутствием данных в справочниках АКВа.
