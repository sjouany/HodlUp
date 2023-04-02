import * as React from "react";
import { Box, Center, Image, Flex, Badge, Text } from "@chakra-ui/react";


export default function MyPlan() {
  return (
    <Center h="100vh">
      <Box className="box" p="5"  borderWidth="1px" position="relative" justify-content="center">
        {/* <Image borderRadius="md" src="https://bit.ly/2k1H1t6" /> */}
        <Box className="box2"p="5"  borderWidth="1px" position="absolute"  top="40"></Box>
        <Flex align="baseline" mt={2}>
          {/* <Badge colorScheme="pink">Plus</Badge> */}
          <Text>
          </Text>
        </Flex>
        <Text>
        </Text>
        <Text mt={2}>$119/night</Text>
        <Flex mt={2} align="center">
          {/* <Box as={MdStar} color="orange.400" /> */}
          <Text ml={1} fontSize="sm">
            <b>4.84</b> (190)
          </Text>
        </Flex>
      </Box>
    </Center>
  );
}