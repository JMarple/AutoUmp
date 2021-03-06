#include <xs1.h>
#include <platform.h>
#include <stdint.h>
#include <stdio.h>
on tile[1]: clock xclk = XS1_CLKBLK_1;

on tile[1]: in  port cam1XCLK = XS1_PORT_1B;
on tile[1]: out port cam1PCLK = XS1_PORT_1A;
on tile[1]: out buffered port:8 cam1DATA = XS1_PORT_8A;
on tile[1]: out buffered port:8 camSYNC  = XS1_PORT_8D;

const uint8_t AU_HREF1 = (1 << 4);
const uint8_t AU_VSYNC1 = (1 << 5);
const uint8_t AU_HREF2 = (1 << 6);
const uint8_t AU_VSYNC2 = (1 << 7);

void dostuff()
{
    printf("Test\n");

    configure_clock_src(xclk, cam1XCLK);
    configure_port_clock_output(cam1PCLK, xclk);
    configure_out_port(cam1DATA, xclk, 0);
    configure_out_port(camSYNC, xclk, 0);
    start_clock(xclk);

    while (1==1)
    {
        camSYNC <: AU_VSYNC1;
        delay_milliseconds(1);
        camSYNC <: 0;

        for (int y = 1; y < 16; y++)
        {
            sync(camSYNC);
            camSYNC <: AU_HREF1;
            for (int x = 1; x < 16; x++)
            {
                cam1DATA <: x;
            }
            camSYNC <: 0;
            cam1DATA <: 0;
            delay_milliseconds(1);
        }

        delay_milliseconds(4);
    }
}

int main()
{
    par
    {
        on tile[1]: dostuff();
    }

    return 0;
}
