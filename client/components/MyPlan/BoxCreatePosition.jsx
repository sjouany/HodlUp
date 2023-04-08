import { Box } from "@chakra-ui/react";
import BoxCreatePositionInput from "./BoxCreatePositionInput";
import BoxCreatePositionOutput from "./BoxCreatePositionOutput";
import { useState } from "react";

function BoxCreatePosition(props) {
  const [tokenFrom, setTokenFrom] = useState("0x");
  const [inputAmount, setInputAmount] = useState(0);

  const handleTokenFromChange = (value) => {
    setTokenFrom(value);
    console.log(tokenFrom);
  };

  const handleInputAmountChange = (value) => {
    setInputAmount(value);
  };

  const handleClick = () => {
    handleInputAmountChange();
    handleTokenFromChange();
  }; 

  return (

    <Box className="box_create_position" p="5" borderWidth="1px" position="relative">
      <BoxCreatePositionInput 
      onTokenFromChange={handleTokenFromChange}
      onInputAmountChange={handleInputAmountChange}
      />
      <BoxCreatePositionOutput 
      tokenFrom={tokenFrom} 
      inputAmount={inputAmount}
      handleClick={handleClick} />
    </Box>
  );
}

export default BoxCreatePosition;
