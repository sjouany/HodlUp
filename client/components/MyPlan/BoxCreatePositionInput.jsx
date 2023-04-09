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

  const [selectedTokenFrom, setSelectedTokenFrom] = useState("0x2791bca1f2de4661ed88a30c99a7a9449aa84174");
  const [inputAmount, setInputAmount] = useState(20);

  const handleTokenChangeFrom = (event) => {
    setSelectedTokenFrom(event.target.value);
    props.onTokenFromChange(selectedTokenFrom);
  };

  const handleInputAmountChange = (valueString) => {
    const newValue = parseFloat(valueString);
    setInputAmount(newValue);
    props.onInputAmountChange(newValue);
  };

  const customOptionsFrom = [
	{ value: "0xe11A86849d99F524cAC3E7A0Ec1241828e332C62", label: "USDC", icon: "USDC.png" },
    { value: "0xA02f6adc7926efeBBd59Fd43A84f4E0c0c91e832", label: "USDT", icon: "USDT.png" },
  ];


  return (
    <Box p="5" borderWidth="0px" position="relative" w='100%' h='30%' >
      < VStack spacing="8" p="4">
        <Text position="absolute" top="0" left="0" fontWeight="bold" color="#28DA98">Make my plan</Text>
        <Text position="absolute" top="0" left="0" fontWeight="bold" color="white">Total amount of your DCA</Text>
        <NumberInput
          precision={2}
          step={0.2}
          top="10"
          left="0"
          position="absolute"
          color="white"
          fontFamily="Inter, sans-serif"
          value={inputAmount}
          onChange={handleInputAmountChange}
          id="input-amount"
        >
          <NumberInputField aria-label="Total amount" />
          <NumberInputStepper>
            <NumberIncrementStepper color="white" aria-label="Increase total amount" />
            <NumberDecrementStepper color="white" aria-label="Decrease total amount" />
          </NumberInputStepper>

        </NumberInput>
      </VStack>
      <Flex justify="flex-end" align="flex-start" position="absolute" top="0" right="0">
        <Select value={selectedTokenFrom} size="lg" onChange={handleTokenChangeFrom} id="token-from" color='#22ba8a'>
          {customOptionsFrom.map((option) => (
            <option key={option.value} value={option.value}>
              <Box>
                <Text>{option.label}</Text>
              </Box>
            </option>
          ))}
        </Select>
      </Flex>
    </Box>
  );
}

export default BoxCreatePositionInput;