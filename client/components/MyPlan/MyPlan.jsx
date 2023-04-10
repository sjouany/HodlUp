import * as React from "react";

import { Center, Flex } from "@chakra-ui/react";
import BoxCreatePosition from "./BoxCreatePosition";
import BoxManagePositions from "./BoxManagePositions";

export default function MyPlan() {

  return (
    <Center h="100vh">
      <Flex justifyContent="center">
        <BoxCreatePosition />
        <BoxManagePositions />
      </Flex>
    </Center>
  );
}
