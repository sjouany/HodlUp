import * as React from "react";
import { useState } from "react";
import { Box, Center, Flex, Icon, Select, VStack, Checkbox, Text, HStack, Image } from "@chakra-ui/react";
import { FaExchangeAlt } from "react-icons/fa";
import BoutonDCA from "./ButtonDCA";

export default function MyPlan() {

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

  const customOptionsFrom = [
    { value: "USDC", label: "USDC", icon: "USDC.png" },
    { value: "USDT", label: "USDT", icon: "USDT.png" },
  ];

  const customOptionsTo = [
    { value: "MATIC", label: "MATIC", icon: "MATIC.png" },
  ];

  const handleSwap = () => {
    console.log("Swap button clicked!");
    setSelectedTokenFrom(selectedTokenFrom === "ETH" ? "USDT" : "ETH");
    setSelectedTokenTo(selectedTokenTo === "ETH" ? "USDT" : "ETH");
  };

  return (
    <Center h="100vh">
      <Box className="box" p="5" borderWidth="1px" position="relative">
        <Box className="box2" p="5" borderWidth="1px" position="absolute" top="40">
          <Flex align="baseline" mt={2}>
            <VStack spacing="4" p="4">
              <Select value={selectedTokenFrom} size='lg' onChange={handleTokenChangeFrom} color='white'>
                {customOptionsFrom.map((option) => (
                  <option key={option.value} value={option.value} color='black'>
                    <HStack spacing="2" color='black'>
                      <Image boxSize="48px" src='USDC.png'/>
                      <Text color='black'>{option.label}</Text>
                    </HStack>
                  </option>
                ))}
              </Select>
              <Icon as={FaExchangeAlt} boxSize={6} onClick={handleSwap} cursor="pointer" css={{ color: "white", caretColor: "white" }} />
              <Select placeholder="Output Token" value={selectedTokenTo} onChange={handleTokenChangeTo}>
                {customOptionsTo.map((option) => (
                  <option key={option.value} value={option.value}>
                    <HStack spacing="2">
                      <Image boxSize="30px" src={option.icon} />
                      <Text>{option.label}</Text>
                    </HStack>
                  </option>
                ))}
              </Select>
              <Flex alignItems="center">
                <Checkbox size="lg" colorScheme="whiteAlpha" />
                <Text ml="2" color="white">
                  Stack & Earn HODL
                </Text>
              </Flex>
              <Flex alignItems="center">
                <BoutonDCA label="Start DCA" handleClick={handleClick} />
              </Flex>
            </VStack>
          </Flex>
        </Box>
      </Box>
    </Center>
  );
}
