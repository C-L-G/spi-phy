# spi-phy
SPI-PHY SLAVE RTL
可综合spi从端口（非Mater 主端口）代码，理论上SPI时钟可以到 system clock的一半，也就是说：如果我的系统时钟是100M，那么这个模块可以支持最高50M的SPI。
如果是快速的SPI（SPI sck 高于 system clock 的一半），则设计思路是不一样的。
当然，SPI sck时钟越低，系统时钟越高，模块越稳定。


仿真需有 C-L-G/spi-model

祝好！

--@--Young--@--

