async function handleChatSubmit(event) {
  event.preventDefault();

  const input = document.getElementById("question-input");
  const question = input.value.trim();

  if (!question) {
    return;
  }

  addMessage("user", question);
  input.value = "";

  addMessage("assistant", "Asking Databricks Genie...");

  try {
    const response = await fetch("/api/chat", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ question }),
    });

    const data = await response.json();

    const chatWindow = document.getElementById("chat-window");
    const lastMessage = chatWindow.lastChild;

    if (!response.ok) {
      lastMessage.textContent = data.detail || "Something went wrong calling Genie.";
      return;
    }

    let responseText = data.answer || "No answer returned from Genie.";

    if (data.generated_sql) {
      responseText += "\n\nGenerated SQL:\n" + data.generated_sql;
    }

    lastMessage.textContent = responseText;
  } catch (error) {
    addMessage("assistant", `Error calling Genie: ${error}`);
  }
}