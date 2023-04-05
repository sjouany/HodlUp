import * as React from "react";

import { Box, Center, Flex, Icon, Select, VStack, Checkbox, Text, HStack, Image } from "@chakra-ui/react";
import { FaExchangeAlt } from "react-icons/fa";
import BoutonDCA from "./ButtonDCA";
import BoxCreatePosition from "./BoxCreatePosition";
import BoxManagePositions from "./BoxManagePositions";

export default function MyPlan() {

  return (
    <Center h="100vh">
      <Flex justifyContent="center">
      <BoxCreatePosition/>
      <BoxManagePositions/>
      </Flex>
    </Center>
  );
}
