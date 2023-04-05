import {
    Box,
    VStack,
    HStack,
    Text,
    NumberInput,
    NumberInputField,
    NumberInputStepper,
    NumberIncrementStepper,
    NumberDecrementStepper,
    Select,
    Image,
    Flex
} from "@chakra-ui/react";

import { useState } from "react";

function BoxCreatePositionInput(props) {

    const [selectedTokenFrom, setSelectedTokenFrom] = useState("");

    const handleTokenChangeFrom = (event) => {
        setSelectedTokenFrom(event.target.value);
      };

    const customOptionsFrom = [
        { value: "USDC", label: "USDC", icon: "USDC.png" },
        { value: "USDT", label: "USDT", icon: "USDT.png" },
      ];

    return (
        <Box p="5" borderWidth="0px" position="relative" w='100%' h='30%' >
            < VStack spacing="8" p="4">
                <Text position="absolute" top="0" left="0" fontWeight="bold" color="#28DA98">Make my plan</Text>
                <Text position="absolute" top="0" left="0" fontWeight="bold" color="white">Total amount of your DCA</Text>
                <NumberInput defaultValue={15}
                    precision={2}
                    step={0.2}
                    top="10"
                    left="0"
                    position="absolute"
                    color="white"
                    fontFamily="Inter, sans-serif"
                >
                    <NumberInputField  />
                    <NumberInputStepper>
                        <NumberIncrementStepper color="white"/>
                        <NumberDecrementStepper color="white" />
                    </NumberInputStepper>
                </NumberInput>
            </VStack>
            <Flex justify="flex-end" align="flex-start" position="absolute" top="0" right="0">
        <Select value={selectedTokenFrom} size="lg" onChange={handleTokenChangeFrom} color="white">
          {customOptionsFrom.map((option) => (
            <option key={option.value} value={option.value} color="black">
              <HStack spacing="2" color="black">
                <Image boxSize="48px" src={option.icon} />
                <Text color="black">{option.label}</Text>
              </HStack>
            </option>
          ))}
        </Select>
      </Flex>
        </Box>
    );
}

export default BoxCreatePositionInput;