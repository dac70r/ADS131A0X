################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (12.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../adc_drivers/ADS131A0x.c 

OBJS += \
./adc_drivers/ADS131A0x.o 

C_DEPS += \
./adc_drivers/ADS131A0x.d 


# Each subdirectory must supply rules for building sources it contributes
adc_drivers/%.o adc_drivers/%.su adc_drivers/%.cyclo: ../adc_drivers/%.c adc_drivers/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -g3 -DDEBUG -DUSE_HAL_DRIVER -DSTM32H743xx -c -I../Core/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc -I../Drivers/STM32H7xx_HAL_Driver/Inc/Legacy -I../Drivers/CMSIS/Device/ST/STM32H7xx/Include -I../Drivers/CMSIS/Include -I"C:/Users/denni/STM32CubeIDE/workspace_1.15.1/ads131a04_drivers/adc_drivers" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-adc_drivers

clean-adc_drivers:
	-$(RM) ./adc_drivers/ADS131A0x.cyclo ./adc_drivers/ADS131A0x.d ./adc_drivers/ADS131A0x.o ./adc_drivers/ADS131A0x.su

.PHONY: clean-adc_drivers

