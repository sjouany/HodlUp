import { Box, RadioGroup, Stack, Radio, Flex, Icon, Select, VStack, Checkbox, Text, HStack, Image } from "@chakra-ui/react";
import ButtonDCA from "./ButtonDCA";
import { FaChevronDown } from "react-icons/fa";
import { useState, useEffect, cloneElement } from "react";


function BoxOutputCreatePosition(props) {
  //70%
  const [tokenFrom, setSelectedTokenFrom] = useState("");
  const [selectedTokenTo, setSelectedTokenTo] = useState("");
  const [inputAmount, setInputAmount] = useState("");
  const [valueInterval, setValueInterval] = useState('604800');
  const [valueIterations, setValueIterations] = useState('604800');
  const [isStaked, setIsStaked] = useState(false);


  useEffect(() => {
    setSelectedTokenFrom(props.tokenFrom);
    setInputAmount(props.inputAmount);
  }, []);


  const handleSwap = () => {
    console.log("Swap button clicked!");
    // setSelectedTokenFrom(selectedTokenFrom === "ETH" ? "USDT" : "ETH");
    // setSelectedTokenTo(selectedTokenTo === "ETH" ? "USDT" : "ETH");
  };


  const handleIsStakedChange = (event) => {
    setIsStaked(event.target.checked);
    console.log("wazzzzzzzzzzaaaaaaaaaaaaaaa");
  };

  // const handleTokenChangeFrom = (event) => {
  //   setSelectedTokenFrom(event.target.value);
  // };

  const handleTokenChangeTo = (event) => {
    setSelectedTokenTo(event.target.value);
  };

  const handleClick = () => {
    console.log("Bouton DCA cliqué !");
  };

  const customOptionsTo = [
    { value: "0xE03489D4E90b22c59c5e23d45DFd59Fc0dB8a025", label: "SAND", icon: "MATIC.png" },
    { value: "0x326C977E6efc84E512bB9C30f76E30c160eD06FB", label: "LINK", icon: "MATIC.png" },
    { value: "0x0000000000000000000000000000000000001010", label: "MATIC", icon: "MATIC.png" }, },
  ];
  return (
    <Box className="box_output_create_position" p="5" borderWidth="1px" position="relative" h="70%">
      <Flex align="baseline" mt={2}>
        <VStack spacing="4" p="0" >
          <Icon as={FaChevronDown} boxSize={6} onClick={handleSwap} cursor="pointer" css={{ color: "white", caretColor: "white" }} position="absolute" top="-15px" />
          <Select value={selectedTokenTo} onChange={handleTokenChangeTo} color='#22ba8a' position="absolute" top="0" width="200px" id="token-to">
            {customOptionsTo.map((option) => (
              <option key={option.value} value={option.value}>
                <Box>
                  <Text>{option.label}</Text>
                </Box>
              </option>
            ))}
          </Select>
          <Flex alignItems="left">
            <VStack spacing="4" p="4">
              <VStack spacing="2" p="2">
                <Text ml="2" color="white">
                  Orders Recurrence
                </Text>
                <RadioGroup onChange={setValueInterval} value={valueInterval} color="white" colorScheme="green">
                  <Stack direction='row'>
                    <Radio value='604800'>Weekly</Radio>
                    <Radio value='2629746'>Monthly</Radio>
                  </Stack>
                </RadioGroup>
              </VStack>
              <VStack spacing="2" p="0">
                <Text ml="2" color="white">
                  How many times
                </Text>
                <RadioGroup onChange={setValueIterations} value={valueIterations} color="white" colorScheme="green">
                  <Stack direction='row'>
                    <Radio value='10'>10</Radio>
                    <Radio value='20'>20</Radio>
                    <Radio value='50'>50</Radio>
                  </Stack>
                </RadioGroup>
              </VStack>
              <HStack spacing="2">
                <Checkbox size="lg" colorScheme="green" id="stake" onChange={handleIsStakedChange} />
                <Text ml="2" color="white">
                  Stack & Earn HODL
                </Text>
              </HStack>
            </VStack>
          </Flex>
          <Flex alignItems="center">
            <ButtonDCA label="Start DCA" handleClick={handleClick} tokenFrom={tokenFrom} inputAmount={inputAmount} />
          </Flex>
        </VStack>
      </Flex>
    </Box>
  );
}

export default BoxOutputCreatePosition;