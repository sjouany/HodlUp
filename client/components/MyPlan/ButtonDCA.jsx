import { Button } from "@chakra-ui/react";

function BoutonDCA(props) {
  return (
    <Button 
    onClick={props.handleClick}
    backgroundColor="#28DA98"
    color="black"
    fontWeight="bold"
    _hover={{ backgroundColor: "#22ba8a" }}
    >
      {props.label}
    </Button>
  );
}

export default BoutonDCA;

