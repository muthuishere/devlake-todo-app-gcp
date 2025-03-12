// src/main/java/apps/todoappgcp/model/Todo.java
package apps.todoappgcp.model;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.relational.core.mapping.Table;

@Data
@Table("TODOS")
public class Todo {
    @Id
    private Long id;
    private String title;
    private String description;
    private boolean completed;
}
