import { Box, Center, Flex, Icon, Select, VStack, Checkbox, Text, HStack, Image } from "@chakra-ui/react";
import { FaExchangeAlt } from "react-icons/fa";
import { useState } from "react";


function BoxManagePositions(props) {

  return (

    <Box className="box_create_position" p="5" borderWidth="1px" position="relative">
    <Box className="box_output_create_position" p="5" borderWidth="1px" position="absolute" top="40">
    <Flex align="baseline" mt={2}>
        <VStack spacing="4" p="4">
        </VStack>
    </Flex>
    </Box>
    </Box>
  );
}

export default BoxManagePositions;