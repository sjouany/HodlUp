import { Box, RadioGroup, Stack, Radio, Flex, Icon, Select, VStack, Checkbox, Text, HStack, Image } from "@chakra-ui/react";
import { FaChevronDown } from "react-icons/fa";
import { useState } from "react";
import ButtonDCA from "./ButtonDCA";
import BoxCreatePositionInput from "./BoxCreatePositionInput";

//la fleche pour switch les liste : FaExchangeAlt
function BoxCreatePosition(props) {

  const [selectedTokenFrom, setSelectedTokenFrom] = useState("");
  const [selectedTokenTo, setSelectedTokenTo] = useState("");


  const handleTokenChangeFrom = (event) => {
    setSelectedTokenFrom(event.target.value);
  };

  const handleTokenChangeTo = (event) => {
    setSelectedTokenTo(event.target.value);
  };

  const handleClick = () => {
    console.log("Bouton DCA cliqué !");
  };

  const customOptionsTo = [
    { value: "MATIC", label: "MATIC", icon: "MATIC.png" },
  ];

  const handleSwap = () => {
    console.log("Swap button clicked!");
    setSelectedTokenFrom(selectedTokenFrom === "ETH" ? "USDT" : "ETH");
    setSelectedTokenTo(selectedTokenTo === "ETH" ? "USDT" : "ETH");
  };

  const [value, setValue] = useState('1')

  return (

    <Box className="box_create_position" p="5" borderWidth="1px" position="relative">
      <BoxCreatePositionInput />
      <Box className="box_output_create_position" p="5" borderWidth="1px" position="relative" h="70%">
        <Flex align="baseline" mt={2}>
          <VStack spacing="4" p="0" >
            <Icon as={FaChevronDown} boxSize={6} onClick={handleSwap} cursor="pointer" css={{ color: "white", caretColor: "white" }} position="absolute" top="-15px" />
            <Select value={selectedTokenTo} onChange={handleTokenChangeTo} color='white' position="absolute" top="0" width="200px" >
              {customOptionsTo.map((option) => (
                <option key={option.value} value={option.value}>
                  <HStack spacing="2">
                    <Image boxSize="30px" src={option.icon} />
                    <Text>{option.label}</Text>
                  </HStack>
                </option>
              ))}
            </Select>
            <Flex alignItems="left">
              <VStack spacing="4" p="4">
                <VStack spacing="2" p="2">
                  <Text ml="2" color="white">
                    Orders Recurrence
                  </Text>
                  <RadioGroup onChange={setValue} value={value} color="white" colorScheme="green">
                    <Stack direction='row'>
                      <Radio value='1'>Weekly</Radio>
                      <Radio value='2'>Monthly</Radio>
                    </Stack>
                  </RadioGroup>
                </VStack>
                <VStack spacing="2" p="0">
                  <Text ml="2" color="white">
                    How many times
                  </Text>
                  <RadioGroup onChange={setValue} value={value} color="white" colorScheme="green">
                    <Stack direction='row'>
                      <Radio value='1'>10</Radio>
                      <Radio value='2'>20</Radio>
                      <Radio value='3'>50</Radio>
                    </Stack>
                  </RadioGroup>
                </VStack>
                <HStack spacing="2">
                  <Checkbox size="lg" colorScheme="green" />
                  <Text ml="2" color="white">
                    Stack & Earn HODL
                  </Text>
                </HStack>
              </VStack>
            </Flex>
            <Flex alignItems="center">
              <ButtonDCA label="Start DCA" handleClick={handleClick} />
            </Flex>
          </VStack>
        </Flex>
      </Box>
    </Box>
  );
}

export default BoxCreatePosition;
