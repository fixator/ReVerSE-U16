# Nintendo Entertainment System (NES)
build 20160813:
- сделал 640x480@60Hz HDMI с поддержкой Audio 2Ch 48kHz
- доработал serializer в hdmi.vhd от Alexey Spirkov, теперь собирается дифпара HDMI_D1 вывод (144,143) 
- обновил прошивку VNC2, переназначил маркер начала пакета на PORT_A1 вывод (12)
- светодиод мигает, если в USB разъём ничего не подключено
- освободил пины SPI Master(USB_CLK, USB_SI, USB_SO, USB_NCS) на VNC2 для загрузчика
- доработал OSD, сделал вывод текста аппаратно (символы 8х8 и буфер 32х8 втиснул в 1 М9К)
- добавил десяток игр на SPI-FLASH
- сделал выбор игр в OSD клавишами [Up],[Down] и [LShift] при зажатой клавише [Win] или с GamePad
- добавил 2x USB GamePad "Defender Game Master G2"